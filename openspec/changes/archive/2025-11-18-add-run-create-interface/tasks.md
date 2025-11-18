# Implementation Tasks

## 1. Backend Implementation
- [x] 1.1 Create GLCommand `CreatePipelineRun` with rollback support
- [x] 1.2 Add `new` and `create` actions to RunsController
- [x] 1.3 Update routes.rb to include `new` and `create` actions

## 2. Frontend Implementation
- [x] 2.1 Create `new.html.erb` view with form
- [x] 2.2 Add pipeline selection dropdown
- [x] 2.3 Add run name input field
- [x] 2.4 Add variables input (JSON or key-value pairs)
- [x] 2.5 Add target folder input
- [x] 2.6 Add "Create Run" button on runs index page

## 3. Testing
- [x] 3.1 Write GLCommand spec for CreatePipelineRun
- [x] 3.2 Write request spec for run creation flow
- [x] 3.3 Test validation errors and edge cases
- [x] 3.4 Test rollback behavior

## 4. Documentation
- [ ] 4.1 Update user guide if exists
- [ ] 4.2 Add inline comments for complex logic
