# Migration Tasks: Merge Fluffy-Train

**Status:** Proposed  
**Updated:** 2025-11-20

---

## Week 1: Foundation

### [ ] Task 1.1: Migrate Personas Pack (1 day)

**Objective:** Establish persona management foundation

**Steps:**
1. [ ] Copy pack from fluffy-train
   ```bash
   cp -r ../fluffy-train/packs/personas packs/
   ```

2. [ ] Copy migration
   ```bash
   cp ../fluffy-train/db/migrate/*_create_personas.rb db/migrate/
   bin/rails db:migrate
   ```

3. [ ] Generate controller and views
   ```bash
   rails g controller Personas index show new create edit update destroy
   ```

4. [ ] Implement PersonasController
   - Index: list all personas
   - Show: persona dashboard (placeholder)
   - New/Create: form to create persona
   - Edit/Update: edit persona details
   - Destroy: soft delete or hard delete

5. [ ] Add routes
   ```ruby
   resources :personas do
     member do
       post :generate_content  # For later
     end
   end
   ```

6. [ ] Test in console
   ```bash
   bin/rails runner "
     persona = Personas.create(name: 'sarah')
     puts persona.success? ? '✅ Created' : persona.full_error_message
   "
   ```

7. [ ] Test in browser
   ```bash
   open http://localhost:3000/personas
   ```

8. [ ] Run pack tests
   ```bash
   bin/rails test packs/personas/test/
   ```

9. [ ] Commit
   ```bash
   git add -A
   git commit -m "Add Personas pack
   
   - Copied packs/personas/ from fluffy-train
   - Migrated personas table
   - Created PersonasController with CRUD
   - Added basic index and show views
   
   Spec: packs/personas/README.md
   Tests: All passing"
   ```

**Acceptance Criteria:**
- [ ] Can create persona via console
- [ ] Can view /personas in browser
- [ ] Can create persona via web form
- [ ] All persona pack tests passing

---

### [ ] Task 1.2: Migrate Content Pillars Pack (1 day)

**Objective:** Add strategic content planning

**Steps:**
1. [ ] Copy pack
   ```bash
   cp -r ../fluffy-train/packs/content_pillars packs/
   ```

2. [ ] Copy migrations
   ```bash
   cp ../fluffy-train/db/migrate/*_create_content_pillars.rb db/migrate/
   cp ../fluffy-train/db/migrate/*_create_pillar_cluster_assignments.rb db/migrate/
   bin/rails db:migrate
   ```

3. [ ] Add pillars section to persona show page
   ```erb
   <!-- app/views/personas/show.html.erb -->
   <section class="pillars">
     <h2>Content Strategy</h2>
     <%= render 'content_pillars/list', pillars: @persona.content_pillars %>
   </section>
   ```

4. [ ] Create content_pillars controller (nested under personas)
   ```bash
   rails g controller ContentPillars --skip-routes
   ```

5. [ ] Add nested routes
   ```ruby
   resources :personas do
     resources :content_pillars
   end
   ```

6. [ ] Implement gap analysis display
   ```ruby
   # In PersonasController#show
   @gap_analysis = ContentPillars::GapAnalyzer.new(persona: @persona).analyze
   ```

7. [ ] Create gap indicator partial
   ```erb
   <!-- app/views/content_pillars/_gap_indicator.html.erb -->
   <span class="gap-status <%= gap[:status] %>">
     <%= gap_status_icon(gap[:status]) %>
     <%= gap[:ready_photos] %> ready
   </span>
   ```

8. [ ] Test gap analysis
   ```bash
   bin/rails runner "
     persona = Persona.first
     pillar = persona.content_pillars.create!(
       name: 'Thanksgiving 2024',
       weight: 30,
       active: true
     )
     gaps = ContentPillars::GapAnalyzer.new(persona: persona).analyze
     puts gaps.inspect
   "
   ```

9. [ ] Run tests
   ```bash
   bin/rails test packs/content_pillars/test/
   ```

10. [ ] Commit
    ```bash
    git add -A
    git commit -m "Add Content Pillars pack
    
    - Strategic theme management with weights
    - Gap analysis service
    - Integrated into persona show page
    - Nested CRUD under personas
    
    Spec: openspec/specs/content-pillars/spec.md
    Tests: All passing"
    ```

**Acceptance Criteria:**
- [ ] Can create pillar via console
- [ ] Pillars visible in persona show page
- [ ] Gap analysis displays correctly
- [ ] All content_pillars tests passing

---

## Week 2: Content Management

### [ ] Task 2.1: Migrate & Adapt Clustering Pack (2 days)

**Objective:** Make clustering work with ImageCandidates

**Day 1: Migration**

1. [ ] Copy pack
   ```bash
   cp -r ../fluffy-train/packs/clustering packs/
   ```

2. [ ] Create new migration for clusters
   ```bash
   rails g migration CreateClusters \
     persona:references \
     name:string \
     status:integer \
     ai_prompt:text \
     photos_count:integer
   ```

3. [ ] Create migration for cluster_candidates join table
   ```bash
   rails g migration CreateClusterCandidates \
     cluster:references \
     candidate_id:bigint:index \
     metadata:jsonb
   ```

4. [ ] Add foreign key to image_candidates
   ```ruby
   # In migration
   add_foreign_key :cluster_candidates, :image_candidates, column: :candidate_id
   ```

5. [ ] Run migrations
   ```bash
   bin/rails db:migrate
   ```

6. [ ] Create ClusterCandidate model
   ```ruby
   # packs/clustering/app/models/clustering/cluster_candidate.rb
   class Clustering::ClusterCandidate < ApplicationRecord
     belongs_to :cluster, class_name: 'Clustering::Cluster'
     belongs_to :candidate, class_name: 'ImageCandidate', foreign_key: :candidate_id
     
     validates :candidate_id, uniqueness: { scope: :cluster_id }
     
     delegate :exportable_url, :elo_score, :pipeline_run, to: :candidate
   end
   ```

**Day 2: Adaptation**

7. [ ] Adapt Cluster model for polymorphic images
   ```ruby
   # packs/clustering/app/models/clustering/cluster.rb
   class Clustering::Cluster < ApplicationRecord
     belongs_to :persona
     has_many :pillar_cluster_assignments, dependent: :destroy
     has_many :content_pillars, through: :pillar_cluster_assignments
     
     # Legacy support
     has_many :photos, dependent: :nullify
     
     # New primary model
     has_many :cluster_candidates, dependent: :destroy
     has_many :image_candidates, 
       through: :cluster_candidates,
       source: :candidate
     
     # Polymorphic accessor
     def images
       photos.to_a + image_candidates.to_a
     end
     
     def image_urls
       photos.map { |p| p.image.url if p.image.attached? }.compact +
       image_candidates.map(&:exportable_url)
     end
     
     def images_count
       photos.count + image_candidates.count
     end
   end
   ```

8. [ ] Test polymorphic behavior
   ```bash
   bin/rails runner "
     persona = Persona.first
     cluster = Clustering::Cluster.create!(
       persona: persona,
       name: 'Test Cluster'
     )
     
     # Link to a turbo-carnival candidate
     candidate = ImageCandidate.where(status: 'active').first
     cluster.cluster_candidates.create!(candidate: candidate)
     
     puts \"Images: #{cluster.images.count}\"
     puts \"URLs: #{cluster.image_urls}\"
   "
   ```

9. [ ] Add clusters to persona show page
   ```erb
   <!-- app/views/personas/show.html.erb -->
   <section class="clusters">
     <h2>Content Library (<%= @persona.clusters.sum(:images_count) %> images)</h2>
     <%= render 'clusters/grid', clusters: @persona.clusters %>
   </section>
   ```

10. [ ] Run tests
    ```bash
    bin/rails test packs/clustering/test/
    ```

11. [ ] Commit
    ```bash
    git commit -am "Add Clustering pack (adapted for ImageCandidate)
    
    - Cluster management with persona/pillar associations
    - ADAPTED: Works with both Photo (legacy) and ImageCandidate
    - Polymorphic image handling via ClusterCandidate join
    - Manual and AI-suggested cluster creation
    
    Spec: openspec/specs/clustering/spec.md (adapted)
    Tests: All passing"
    ```

**Acceptance Criteria:**
- [ ] Can create cluster via console
- [ ] Can link ImageCandidate to cluster
- [ ] cluster.images returns both photos and candidates
- [ ] cluster.image_urls returns exportable URLs
- [ ] Clusters visible in persona show page

---

### [ ] Task 2.2: Link Pipelines to Clusters (1 day)

**Objective:** Auto-link winner on run completion

**Steps:**

1. [ ] Create migration
   ```bash
   rails g migration AddClusterAndPersonaToPipelines \
     persona:references \
     cluster:references
   ```

2. [ ] Run migration
   ```bash
   bin/rails db:migrate
   ```

3. [ ] Add associations to Pipeline
   ```ruby
   # app/models/pipeline.rb
   class Pipeline < ApplicationRecord
     belongs_to :persona, optional: true
     belongs_to :cluster, 
       class_name: 'Clustering::Cluster',
       optional: true
     
     validates :persona, presence: true, if: :cluster_id?
     
     def content_generation?
       persona_id.present? && cluster_id.present?
     end
   end
   ```

4. [ ] Add auto-linking to PipelineRun
   ```ruby
   # packs/pipeline/app/models/pipeline_run.rb
   class PipelineRun < ApplicationRecord
     after_update :link_winner_to_cluster, if: -> { 
       saved_change_to_status? &&
       completed? && 
       pipeline.cluster_id.present?
     }
     
     private
     
     def link_winner_to_cluster
       winner = final_step_winner
       return unless winner
       
       Clustering::ClusterCandidate.find_or_create_by!(
         cluster_id: pipeline.cluster_id,
         candidate_id: winner.id
       ) do |cc|
         cc.metadata = {
           elo_score: winner.elo_score,
           run_name: name,
           completed_at: updated_at,
           linked_at: Time.current
         }
       end
       
       Rails.logger.info "✅ Linked candidate #{winner.id} to cluster #{pipeline.cluster_id}"
     end
     
     def final_step_winner
       final_step = pipeline.pipeline_steps.order(:order).last
       ImageCandidate
         .where(
           pipeline_step: final_step,
           pipeline_run: self,
           status: 'active'
         )
         .order(elo_score: :desc)
         .first
     end
   end
   ```

5. [ ] Test auto-linking
   ```bash
   bin/rails runner "
     persona = Persona.first
     cluster = persona.clusters.create!(name: 'Test Auto-Link')
     
     pipeline = Pipeline.first
     pipeline.update!(persona: persona, cluster: cluster)
     
     run = PipelineRun.create!(pipeline: pipeline, name: 'test-run')
     
     # ... create steps, candidates, complete run ...
     
     run.update!(status: 'completed')
     
     # Check if winner was linked
     puts \"Cluster images: #{cluster.reload.images.count}\"
   "
   ```

6. [ ] Add visual indicator in run show page
   ```erb
   <!-- app/views/runs/show.html.erb -->
   <% if @run.completed? && @run.pipeline.cluster %>
     <div class="success-banner">
       ✅ Winner linked to cluster: <%= link_to @run.pipeline.cluster.name, persona_cluster_path(@run.pipeline.persona, @run.pipeline.cluster) %>
     </div>
   <% end %>
   ```

7. [ ] Run tests
   ```bash
   bin/rails test test/models/pipeline_run_test.rb
   ```

8. [ ] Commit
   ```bash
   git commit -am "Connect Pipelines to Clusters with auto-linking
   
   - Added persona_id and cluster_id to pipelines
   - Auto-link winner to cluster on run completion
   - Preserve ELO score and metadata in join table
   - Visual indicator when winner is linked
   
   Feature: Run completion → winner automatically added to content library
   Tests: All passing"
   ```

**Acceptance Criteria:**
- [ ] Pipeline can be linked to persona and cluster
- [ ] Completing a run auto-links winner to cluster
- [ ] Winner appears in cluster.images
- [ ] Success banner shows in run show page

---

## Week 3: AI Services

### [ ] Task 3.1: Migrate AI Content Generation (1 day)

**Objective:** AI-driven prompt generation and pipeline creation

**Steps:**

1. [ ] Copy AI libraries
   ```bash
   cp -r ../fluffy-train/lib/ai lib/
   ```

2. [ ] Add gem dependency
   ```bash
   echo 'gem "ruby-openai"' >> Gemfile
   bundle install
   ```

3. [ ] Add environment variable
   ```bash
   echo "GEMINI_API_KEY=your_key_here" >> .env
   ```

4. [ ] Test AI client
   ```bash
   bin/rails runner "
     client = AI::GeminiClient.new
     response = client.generate('Test prompt')
     puts response
   "
   ```

5. [ ] Test prompt generator
   ```bash
   bin/rails runner "
     persona = Persona.first
     pillar = persona.content_pillars.first
     
     prompts = AI::ContentPromptGenerator.generate(
       persona: persona,
       pillar: pillar,
       count: 3
     )
     
     puts prompts.inspect
   "
   ```

6. [ ] Create CreateContentPipeline service
   ```ruby
   # app/services/create_content_pipeline.rb
   class CreateContentPipeline
     def self.call(persona:, pillar:)
       # Generate AI prompt
       prompt_data = AI::ContentPromptGenerator.generate(
         persona: persona,
         pillar: pillar,
         count: 1
       ).first
       
       # Create cluster with prompt
       cluster = Clustering::Cluster.create!(
         persona: persona,
         name: prompt_data[:scene],
         ai_prompt: prompt_data[:full_prompt]
       )
       
       cluster.pillar_cluster_assignments.create!(pillar: pillar)
       
       # Find or create default pipeline template
       pipeline = Pipeline.find_or_create_by(
         name: "Default Portrait Pipeline"
       ) do |p|
         create_default_steps(p)
       end
       
       # Create run
       run = PipelineRun.create!(
         pipeline: pipeline,
         name: cluster.name.parameterize,
         metadata: {
           cluster_id: cluster.id,
           pillar_id: pillar.id,
           ai_prompt: prompt_data[:full_prompt]
         }
       )
       
       # Link pipeline to cluster for auto-linking
       pipeline.update!(persona: persona, cluster: cluster)
       
       { cluster: cluster, pipeline: pipeline, run: run }
     end
     
     private
     
     def self.create_default_steps(pipeline)
       ['Base Image', 'Enhance Body', 'Replace Face', 'Replace Hands', 'Upscale'].each_with_index do |name, i|
         pipeline.pipeline_steps.create!(name: name, order: i + 1)
       end
     end
   end
   ```

7. [ ] Add generate_content action to PersonasController
   ```ruby
   def generate_content
     @persona = Persona.find(params[:id])
     pillar = @persona.content_pillars.find(params[:pillar_id])
     
     result = CreateContentPipeline.call(
       persona: @persona,
       pillar: pillar
     )
     
     redirect_to run_path(result[:run]),
       notice: "Created pipeline for #{pillar.name}. Start voting to select best candidates!"
   end
   ```

8. [ ] Add "Generate Content" button to pillar cards
   ```erb
   <!-- app/views/personas/show.html.erb -->
   <% @gap_analysis.each do |gap| %>
     <% if gap[:status].in?([:critical, :low]) %>
       <%= button_to "Generate Content", 
           generate_content_persona_path(@persona, pillar_id: gap[:pillar].id),
           method: :post,
           class: "btn btn-primary" %>
     <% end %>
   <% end %>
   ```

9. [ ] Test full workflow
   ```bash
   # Via browser:
   # 1. Go to /personas/1
   # 2. Click "Generate Content" on pillar
   # 3. Should redirect to voting page
   # 4. Complete run
   # 5. Check cluster has winner
   ```

10. [ ] Commit
    ```bash
    git commit -am "Add AI Content Generation
    
    - Gemini API client integration
    - Content prompt generator with persona awareness
    - CreateContentPipeline service
    - 'Generate Content' button in persona dashboard
    
    Spec: openspec/specs/ai-content-generation/spec.md
    Tests: All passing"
    ```

**Acceptance Criteria:**
- [ ] AI client works (generates text)
- [ ] Prompt generator creates valid prompts
- [ ] "Generate Content" creates cluster + pipeline + run
- [ ] Run uses AI prompt in metadata

---

### [ ] Task 3.2: Migrate Caption Generation (1 day)

**Steps:**
1. [ ] Copy pack: `cp -r ../fluffy-train/packs/caption_generations packs/`
2. [ ] Copy migrations: `cp ../fluffy-train/db/migrate/*_caption*.rb db/migrate/`
3. [ ] Run migrations: `bin/rails db:migrate`
4. [ ] Test caption generation with ImageCandidate
5. [ ] Run tests: `bin/rails test packs/caption_generations/test/`
6. [ ] Commit

**Acceptance Criteria:**
- [ ] Can generate caption for ImageCandidate
- [ ] All tests passing

---

### [ ] Task 3.3: Migrate Hashtag Generation (0.5 days)

**Steps:**
1. [ ] Copy pack: `cp -r ../fluffy-train/packs/hashtag_generations packs/`
2. [ ] Copy migrations
3. [ ] Run migrations
4. [ ] Test hashtag generation
5. [ ] Run tests
6. [ ] Commit

**Acceptance Criteria:**
- [ ] Can generate hashtags
- [ ] All tests passing

---

## Week 4: Strategy & Scheduling

### [ ] Task 4.1: Migrate Content Strategy (1.5 days)

**Objective:** Smart content selection with polymorphic image handling

**Steps:**

1. [ ] Copy pack
   ```bash
   cp -r ../fluffy-train/packs/content_strategy packs/
   ```

2. [ ] Copy migrations
   ```bash
   cp ../fluffy-train/db/migrate/*_content_strategy*.rb db/migrate/
   bin/rails db:migrate
   ```

3. [ ] Adapt Selector for ImageCandidates
   ```ruby
   # packs/content_strategy/app/services/content_strategy/selector.rb
   class ContentStrategy::Selector
     def select_next_content
       # ... existing pillar-aware logic ...
       
       # Returns Photo OR ClusterCandidate
       selected = select_from_eligible_clusters
       
       # Wrap in polymorphic wrapper
       ImageWrapper.new(selected)
     end
     
     private
     
     def select_from_eligible_clusters
       # ... existing selection logic ...
       # Now works with clusters that have ImageCandidates
     end
   end
   ```

4. [ ] Create ImageWrapper
   ```ruby
   # app/models/image_wrapper.rb
   class ImageWrapper
     def initialize(source)
       @source = source
     end
     
     def url
       case @source
       when Photos::Photo
         @source.image.url
       when Clustering::ClusterCandidate
         @source.candidate.cached_exportable_url
       when ImageCandidate
         @source.cached_exportable_url
       else
         raise "Unknown source: #{@source.class}"
       end
     end
     
     def metadata
       case @source
       when Photos::Photo
         { aesthetic_score: @source.aesthetic_score }
       when Clustering::ClusterCandidate
         { 
           elo_score: @source.candidate.elo_score,
           pipeline: @source.candidate.pipeline_run&.name
         }
       when ImageCandidate
         { elo_score: @source.elo_score }
       end
     end
     
     def source
       @source
     end
   end
   ```

5. [ ] Test selection
   ```bash
   bin/rails runner "
     persona = Persona.first
     selector = ContentStrategy::Selector.new(persona: persona)
     
     selected = selector.select_next_content
     puts \"Selected: #{selected.source.class}\"
     puts \"URL: #{selected.url}\"
     puts \"Metadata: #{selected.metadata}\"
   "
   ```

6. [ ] Create preview controller
   ```ruby
   # app/controllers/content_strategy_controller.rb
   class ContentStrategyController < ApplicationController
     def preview
       @persona = Persona.find(params[:persona_id])
       selector = ContentStrategy::Selector.new(persona: @persona)
       @selected = selector.select_next_content
     end
   end
   ```

7. [ ] Create preview view
   ```erb
   <!-- app/views/content_strategy/preview.html.erb -->
   <h1>Next Post Preview</h1>
   
   <div class="preview-card">
     <img src="<%= @selected.url %>" alt="Selected image">
     
     <div class="metadata">
       <% @selected.metadata.each do |key, value| %>
         <p><strong><%= key %>:</strong> <%= value %></p>
       <% end %>
     </div>
     
     <%= link_to "Schedule This Post", "#", class: "btn btn-primary" %>
   </div>
   ```

8. [ ] Run tests
   ```bash
   bin/rails test packs/content_strategy/test/
   ```

9. [ ] Commit
   ```bash
   git commit -am "Add Content Strategy pack
   
   - Intelligent content selection
   - Pillar-aware rotation
   - Polymorphic image handling (Photo + ImageCandidate)
   - Preview interface
   
   Spec: openspec/specs/content-strategy/spec.md
   Tests: All passing"
   ```

**Acceptance Criteria:**
- [ ] Selector works with ImageCandidates
- [ ] Preview shows selected content
- [ ] Respects pillar weights
- [ ] All tests passing

---

### [ ] Task 4.2: Migrate Scheduling & Instagram (1 day)

**Steps:**

1. [ ] Copy pack and Instagram lib
   ```bash
   cp -r ../fluffy-train/packs/scheduling packs/
   cp -r ../fluffy-train/lib/instagram lib/
   ```

2. [ ] Add gem
   ```bash
   echo 'gem "instagram_graph_api"' >> Gemfile
   bundle install
   ```

3. [ ] Add Instagram credentials
   ```bash
   bin/rails credentials:edit
   # Add:
   # instagram:
   #   app_id: "..."
   #   app_secret: "..."
   #   access_token: "..."
   #   account_id: "..."
   ```

4. [ ] Copy migrations
   ```bash
   cp ../fluffy-train/db/migrate/*_scheduling*.rb db/migrate/
   bin/rails db:migrate
   ```

5. [ ] Adapt Post model for ImageCandidate URLs
   ```ruby
   # packs/scheduling/app/models/scheduling/post.rb
   class Scheduling::Post < ApplicationRecord
     # Can store image_url directly (from ImageCandidate.exportable_url)
     # Or link to cluster_candidate
     
     validates :image_url, presence: true
     
     def post_to_instagram!
       Instagram::APIClient.post(
         image_url: image_url,
         caption: caption,
         hashtags: hashtags
       )
     end
   end
   ```

6. [ ] Create schedule action
   ```ruby
   # app/controllers/personas_controller.rb
   def schedule_post
     @persona = Persona.find(params[:id])
     selector = ContentStrategy::Selector.new(persona: @persona)
     selected = selector.select_next_content
     
     # Generate caption and hashtags
     caption = CaptionGenerations::Generator.generate(
       image: selected.source,
       persona: @persona
     )
     
     hashtags = HashtagGenerations::Generator.generate(
       image: selected.source,
       persona: @persona
     )
     
     # Create scheduled post
     post = Scheduling::Post.create!(
       persona: @persona,
       image_url: selected.url,
       caption: caption,
       hashtags: hashtags,
       scheduled_for: 1.hour.from_now,
       status: 'scheduled'
     )
     
     redirect_to persona_path(@persona),
       notice: "Post scheduled for #{post.scheduled_for.strftime('%I:%M %p')}"
   end
   ```

7. [ ] Add scheduling UI to persona show
   ```erb
   <!-- app/views/personas/show.html.erb -->
   <section class="scheduling">
     <h2>Upcoming Posts</h2>
     <% @upcoming_posts.each do |post| %>
       <%= render 'scheduling/post_card', post: post %>
     <% end %>
     
     <%= link_to "Schedule Next Post", 
         schedule_post_persona_path(@persona),
         method: :post,
         class: "btn btn-primary" %>
   </section>
   ```

8. [ ] Test scheduling
   ```bash
   bin/rails runner "
     persona = Persona.first
     # ... create post ...
     # Don't actually post to Instagram in dev
   "
   ```

9. [ ] Commit
   ```bash
   git commit -am "Add Scheduling pack
   
   - Post scheduling with Instagram integration
   - Works with ImageCandidate URLs
   - AI-generated captions and hashtags
   - Scheduling UI in persona dashboard
   
   Spec: Scheduling and posting workflow
   Tests: All passing"
   ```

**Acceptance Criteria:**
- [ ] Can schedule post with ImageCandidate URL
- [ ] Caption and hashtags generated
- [ ] Upcoming posts visible in persona dashboard

---

## Week 5: UI & Polish

### [ ] Task 5.1: Build Unified Dashboard (2 days)

**Day 1: Persona Dashboard**

1. [ ] Build comprehensive persona show page
   ```erb
   <!-- app/views/personas/show.html.erb -->
   <div class="persona-dashboard">
     <!-- Header -->
     <header>
       <h1><%= @persona.name %></h1>
       <p><%= @persona.description %></p>
       <%= link_to "Edit", edit_persona_path(@persona) %>
     </header>
     
     <!-- Content Strategy Section -->
     <section class="pillars">
       <h2>Content Strategy</h2>
       <div class="gap-analysis">
         <% @gap_analysis.each do |gap| %>
           <%= render 'content_pillars/pillar_card', gap: gap, persona: @persona %>
         <% end %>
       </div>
     </section>
     
     <!-- Active Pipelines Section -->
     <section class="pipelines">
       <h2>Active Pipelines</h2>
       <% @pipelines.each do |pipeline| %>
         <%= render 'pipelines/pipeline_card', pipeline: pipeline %>
       <% end %>
     </section>
     
     <!-- Recent Runs Section -->
     <section class="recent-runs">
       <h2>Recent Runs</h2>
       <% @recent_runs.each do |run| %>
         <%= render 'runs/run_item', run: run %>
       <% end %>
     </section>
     
     <!-- Content Library Section -->
     <section class="clusters">
       <h2>Content Library (<%= @persona.clusters.sum(&:images_count) %> images)</h2>
       <div class="clusters-grid">
         <% @clusters.each do |cluster| %>
           <%= render 'clusters/cluster_card', cluster: cluster %>
         <% end %>
       </div>
     </section>
     
     <!-- Scheduling Section -->
     <section class="schedule">
       <h2>Upcoming Posts</h2>
       <% @upcoming_posts.each do |post| %>
         <%= render 'scheduling/post_card', post: post %>
       <% end %>
       
       <%= link_to "Schedule Next Post", 
           schedule_post_persona_path(@persona),
           method: :post,
           class: "btn btn-primary" %>
     </section>
   </div>
   ```

2. [ ] Update PersonasController#show to load all data
   ```ruby
   def show
     @persona = Persona.find(params[:id])
     @pillars = @persona.content_pillars.active.order(priority: :desc)
     @gap_analysis = @persona.gap_analysis # Cached
     @pipelines = Pipeline.where(persona: @persona).order(created_at: :desc).limit(5)
     @recent_runs = PipelineRun.joins(:pipeline)
       .where(pipelines: { persona_id: @persona.id })
       .order(created_at: :desc)
       .limit(10)
     @clusters = @persona.clusters.includes(:image_candidates, :photos)
     @upcoming_posts = Scheduling::Post
       .where(persona: @persona, status: 'scheduled')
       .order(:scheduled_for)
       .limit(5)
   end
   ```

**Day 2: Supporting Views & Styling**

3. [ ] Create partial views
   - [ ] `_pillar_card.html.erb` - Pillar with gap indicator and "Generate" button
   - [ ] `_pipeline_card.html.erb` - Pipeline status and link to runs
   - [ ] `_run_item.html.erb` - Run with status and voting link
   - [ ] `_cluster_card.html.erb` - Cluster with image preview
   - [ ] `_post_card.html.erb` - Scheduled post preview

4. [ ] Add basic styling (Tailwind or custom CSS)
   ```css
   /* Gap status colors */
   .gap-status.ready { color: green; }
   .gap-status.low { color: orange; }
   .gap-status.critical { color: red; }
   
   /* Grid layouts */
   .clusters-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
   .pillars-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; }
   ```

5. [ ] Add helper methods
   ```ruby
   # app/helpers/personas_helper.rb
   def gap_status_icon(status)
     case status
     when :ready then "✅"
     when :low then "⚠️"
     when :critical then "🚨"
     when :exhausted then "⏸️"
     else "❓"
     end
   end
   
   def run_status_badge(run)
     case run.status
     when 'completed' then content_tag(:span, "✅ Complete", class: "badge badge-success")
     when 'running' then content_tag(:span, "🔄 Running", class: "badge badge-warning")
     else content_tag(:span, run.status.titleize, class: "badge badge-secondary")
     end
   end
   ```

6. [ ] Update navigation
   ```erb
   <!-- app/views/layouts/application.html.erb -->
   <nav>
     <%= link_to "Personas", personas_path, class: "nav-link" %>
     <%= link_to "All Runs", runs_path, class: "nav-link" %>
     <%= link_to "Gallery", runs_path, class: "nav-link" %>
   </nav>
   ```

7. [ ] Test full dashboard
   ```bash
   # Create test data
   bin/rails runner "
     persona = Persona.create!(name: 'Test User')
     pillar = persona.content_pillars.create!(name: 'Test Pillar', weight: 50)
     cluster = persona.clusters.create!(name: 'Test Cluster')
   "
   
   # View in browser
   open http://localhost:3000/personas/1
   ```

8. [ ] Commit
   ```bash
   git commit -am "Build unified persona dashboard
   
   - Comprehensive persona show page
   - Content strategy with gap indicators
   - Active pipelines monitoring
   - Content library view
   - Scheduling interface
   - Supporting partials and helpers
   
   Feature: Complete web-based workflow
   Tests: UI manually validated"
   ```

**Acceptance Criteria:**
- [ ] Persona dashboard shows all sections
- [ ] Gap analysis visible with status icons
- [ ] "Generate Content" button works
- [ ] Active pipelines show with links to voting
- [ ] Clusters display with image counts
- [ ] Upcoming posts visible
- [ ] "Schedule Post" button works

---

### [ ] Task 5.2: Testing & Polish (1 day)

**Steps:**

1. [ ] End-to-end workflow test
   ```bash
   # Full workflow:
   # 1. Create persona
   # 2. Create pillar with weight
   # 3. Click "Generate Content"
   # 4. Vote on candidates
   # 5. Approve gates
   # 6. Mark complete
   # 7. Verify winner in cluster
   # 8. Schedule post
   # 9. Verify post scheduled
   ```

2. [ ] Run all tests
   ```bash
   bin/rails test
   bin/rails test:system  # If you have system tests
   ```

3. [ ] Check Packwerk violations
   ```bash
   bin/packwerk check
   ```

4. [ ] Update README
   ```markdown
   # Turbo-Carnival: Unified Content Creation Platform
   
   ## Features
   - Persona-based content management
   - AI-driven image generation pipelines
   - ELO ranking and approval gates
   - Content strategy and gap analysis
   - Instagram scheduling and posting
   
   ## Quick Start
   1. Create a persona
   2. Define content pillars
   3. Generate content via AI
   4. Vote on candidates
   5. Schedule posts to Instagram
   ```

5. [ ] Copy fluffy-train OpenSpecs
   ```bash
   cp -r ../fluffy-train/openspec/specs/* openspec/specs/
   ```

6. [ ] Create migration summary doc
   ```bash
   cat > docs/fluffy-train-migration.md << 'EOF'
   # Fluffy-Train Migration
   
   Completed: 2025-11-XX
   
   ## What Was Migrated
   - All fluffy-train packs
   - AI services (Gemini client)
   - Instagram integration
   - Content strategy
   - Scheduling
   
   ## Key Adaptations
   - Clustering pack adapted for ImageCandidate
   - Web UI built (replacing TUI)
   - Auto-linking on run completion
   
   ## Deprecation
   - fluffy-train repository archived
   - TUI discontinued (web UI replaces it)
   EOF
   ```

7. [ ] Final commit
   ```bash
   git commit -am "Polish and documentation
   
   - End-to-end testing complete
   - README updated
   - OpenSpecs copied from fluffy-train
   - Migration documentation added
   
   Status: Merge complete ✅"
   ```

**Acceptance Criteria:**
- [ ] All tests passing
- [ ] No Packwerk violations
- [ ] README updated
- [ ] Full workflow validated
- [ ] Documentation complete

---

## Post-Migration Tasks

### [ ] Deprecate Fluffy-Train

1. [ ] Archive fluffy-train repository
   ```bash
   cd ../fluffy-train
   git tag -a "archived-$(date +%Y-%m-%d)" -m "Merged into turbo-carnival"
   git push --tags
   
   # Update README
   echo "# ARCHIVED: Merged into Turbo-Carnival" > README.md
   echo "See: https://github.com/timlawrenz/turbo-carnival" >> README.md
   git commit -am "Archive: Merged into turbo-carnival"
   git push
   ```

2. [ ] Update links and references
   - Update any external documentation
   - Redirect users to unified app

### [ ] Optional: Deploy to Production

1. [ ] Deploy to Heroku/Kamal/etc
2. [ ] Run migrations on production
3. [ ] Verify Instagram integration works
4. [ ] Monitor for errors

---

## Progress Tracking

**Overall Progress:** 0/10 major migrations complete

### Week 1
- [ ] Personas pack
- [ ] Content Pillars pack

### Week 2
- [ ] Clustering pack (adapted)
- [ ] Pipeline linking

### Week 3
- [ ] AI Content Generation
- [ ] Caption Generation
- [ ] Hashtag Generation

### Week 4
- [ ] Content Strategy
- [ ] Scheduling

### Week 5
- [ ] Unified Dashboard
- [ ] Polish & Testing

---

## Notes

- Each task should be a separate git commit
- Test after each migration before moving on
- Keep fluffy-train running in parallel during migration
- Document any issues or deviations in commit messages
