# Clustering Spec Delta: Photo Upload

**Change ID:** `add-photo-upload-to-cluster`  
**Target Spec:** `clustering` (new spec, will be created)

## ADDED Requirements

### Requirement: Manual Photo Upload to Cluster
The system SHALL allow users to manually upload one or more photos directly to a cluster via the web interface.

#### Scenario: User uploads single photo to cluster
- **GIVEN** a user is viewing cluster "2025 Fashion" (ID: 11)
- **WHEN** the user clicks "Upload Photos"
- **AND** selects a single JPG file "fashion-shot-1.jpg" (5MB)
- **AND** submits the upload
- **THEN** a new Photo record is created
- **AND** the photo is linked to cluster 11
- **AND** the photo is linked to the cluster's persona
- **AND** the photo appears in the cluster gallery
- **AND** a success message is displayed

#### Scenario: User uploads multiple photos to cluster
- **GIVEN** a user is viewing cluster "2025 Fashion"
- **WHEN** the user selects 5 JPG files totaling 25MB
- **AND** submits the upload
- **THEN** 5 new Photo records are created
- **AND** all photos are linked to the cluster
- **AND** all photos are linked to the cluster's persona
- **AND** all photos appear in the cluster gallery
- **AND** the cluster photo count increases by 5

#### Scenario: User attempts to upload invalid file type
- **GIVEN** a user is viewing a cluster
- **WHEN** the user selects a .txt file
- **AND** submits the upload
- **THEN** an error message is displayed: "Invalid file type. Accepted: JPG, PNG, WEBP"
- **AND** no Photo record is created
- **AND** the cluster photo count remains unchanged

#### Scenario: User attempts to upload oversized file
- **GIVEN** a user is viewing a cluster
- **WHEN** the user selects a JPG file that is 15MB
- **AND** submits the upload
- **THEN** an error message is displayed: "File too large. Maximum size: 10MB"
- **AND** no Photo record is created

#### Scenario: User uploads mix of valid and invalid files
- **GIVEN** a user is viewing a cluster
- **WHEN** the user selects 3 files:
  - "photo1.jpg" (5MB, valid)
  - "photo2.txt" (1KB, invalid type)
  - "photo3.png" (12MB, too large)
- **AND** submits the upload
- **THEN** 1 Photo record is created for "photo1.jpg"
- **AND** error messages are displayed for the 2 failed files
- **AND** the cluster photo count increases by 1
- **AND** a partial success message is displayed: "1 photo uploaded successfully, 2 failed"

### Requirement: Photo Upload File Validation
The system SHALL validate uploaded photo files before creating Photo records.

#### Scenario: Validate supported file formats
- **WHEN** a file with extension .jpg, .jpeg, .png, or .webp is uploaded
- **THEN** the file is accepted for processing

#### Scenario: Reject unsupported file formats
- **WHEN** a file with extension .gif, .bmp, .txt, or any other format is uploaded
- **THEN** the file is rejected with error message
- **AND** the error specifies accepted formats

#### Scenario: Validate file size limits
- **WHEN** a file of size 10MB or less is uploaded
- **THEN** the file is accepted for processing

#### Scenario: Reject oversized files
- **WHEN** a file larger than 10MB is uploaded
- **THEN** the file is rejected with error message
- **AND** the error specifies the maximum allowed size

### Requirement: Photo Upload User Interface
The system SHALL provide an intuitive upload interface on the cluster detail page.

#### Scenario: Upload button is visible on cluster page
- **WHEN** a user navigates to a cluster detail page
- **THEN** an "Upload Photos" button or section is visible
- **AND** the button displays a clear call-to-action

#### Scenario: File picker supports multiple selection
- **WHEN** a user clicks the upload button/area
- **THEN** a file picker dialog opens
- **AND** the picker allows selecting multiple files simultaneously

#### Scenario: Upload progress is shown
- **WHEN** a user submits files for upload
- **THEN** a progress indicator is displayed
- **AND** the indicator shows upload status
- **AND** the user can see when upload completes

#### Scenario: Upload results are communicated clearly
- **WHEN** an upload completes successfully
- **THEN** a success message is displayed
- **AND** the message indicates how many photos were uploaded
- **AND** the cluster gallery updates to show new photos

### Requirement: Photo Upload Storage Integration
The system SHALL use ActiveStorage to handle uploaded photo files.

#### Scenario: Photo file is stored via ActiveStorage
- **WHEN** a valid photo file is uploaded
- **THEN** the file is stored using ActiveStorage
- **AND** the storage location follows the configured ActiveStorage backend (disk/S3)
- **AND** a blob record is created in ActiveStorage

#### Scenario: Photo record links to ActiveStorage attachment
- **WHEN** a Photo record is created from upload
- **THEN** the Photo's `image` attachment is populated
- **AND** the attachment links to the ActiveStorage blob
- **AND** the photo can be accessed via photo.image

## Implementation Notes

### Route
```ruby
# config/routes.rb
resources :personas do
  resources :pillars, controller: 'content_pillars' do
    resources :clusters, controller: 'clustering/clusters' do
      member do
        post :upload_photos
      end
    end
  end
end
```

### Controller Action
```ruby
# app/controllers/clustering/clusters_controller.rb
def upload_photos
  uploaded_photos = []
  failed_uploads = []
  
  params[:photos].each do |photo_file|
    # Validate file
    unless valid_photo_format?(photo_file)
      failed_uploads << { file: photo_file.original_filename, error: "Invalid file type" }
      next
    end
    
    unless valid_photo_size?(photo_file)
      failed_uploads << { file: photo_file.original_filename, error: "File too large" }
      next
    end
    
    # Create photo
    photo = Clustering::Photo.create!(
      persona: @cluster.persona,
      cluster: @cluster,
      path: generate_upload_path(photo_file)
    )
    
    photo.image.attach(photo_file)
    uploaded_photos << photo
  end
  
  render json: {
    success: uploaded_photos.count,
    failed: failed_uploads.count,
    photos: uploaded_photos.map(&:id),
    errors: failed_uploads
  }
end
```

### Validations
```ruby
# app/models/clustering/photo.rb
ALLOWED_FORMATS = %w[.jpg .jpeg .png .webp].freeze
MAX_FILE_SIZE = 10.megabytes

validate :image_format, if: -> { image.attached? }
validate :image_size, if: -> { image.attached? }

private

def image_format
  return unless image.attached?
  
  extension = File.extname(image.filename.to_s).downcase
  unless ALLOWED_FORMATS.include?(extension)
    errors.add(:image, "must be JPG, PNG, or WEBP")
  end
end

def image_size
  return unless image.attached?
  
  if image.blob.byte_size > MAX_FILE_SIZE
    errors.add(:image, "is too large (maximum: 10MB)")
  end
end
```

## Acceptance Criteria

- ✅ User can upload 1+ photos to a cluster
- ✅ Supports JPG, PNG, WEBP formats
- ✅ Rejects invalid file types with clear error
- ✅ Rejects files over 10MB with clear error
- ✅ Photos appear in cluster gallery immediately
- ✅ Photos are linked to correct cluster and persona
- ✅ Progress indicator shown during upload
- ✅ Success/error messages displayed appropriately
- ✅ Handles partial success (some files valid, some invalid)
