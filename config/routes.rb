Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Mount importmap for JavaScript modules
  mount Importmap::Engine, at: "/importmap"

  # Runs dashboard (main entry point)
  resources :runs, only: [:index, :show, :new, :create] do
    member do
      post :complete  # POST /runs/14/complete
      get :winners    # GET /runs/14/winners
      get :card       # GET /runs/14/card (for Turbo Frame refresh)
    end
    
    # Voting scoped to run
    get 'vote', to: 'image_votes#show'           # GET  /runs/14/vote
    post 'vote', to: 'image_votes#vote'          # POST /runs/14/vote
    post 'vote/reject/:id', to: 'image_votes#reject', as: :reject_vote
                                                  # POST /runs/14/vote/reject/123
    
    # Gallery scoped to run
    get 'gallery', to: 'gallery#index'            # GET /runs/14/gallery?step=2
    post 'gallery/reject/:id', to: 'gallery#reject', as: :gallery_reject
                                                  # POST /runs/14/gallery/reject/123
    post 'steps/:step_id/approve', to: 'gallery#approve_step', as: :approve_step
                                                  # POST /runs/14/steps/2/approve
  end
  
  # Legacy routes (redirect to first active run)
  get "vote" => "redirects#vote"
  get "gallery" => "redirects#gallery"
  
  # Winners gallery
  get "winners" => "winners#index", as: :winners

  # Image serving (global, no run scope needed)
  get "images/:id" => "images#show", as: :candidate_image

  # Defines the root path route ("/")
  root "runs#index"
end
