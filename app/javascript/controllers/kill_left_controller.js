import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["parentButton"]
  
  navigateToParent(event) {
    // This controller handles the kill-left navigation workflow
    // When a user kills an image, the backend sets up navigation to the parent
    // The controller just needs to submit the kill form
    // The backend will handle redirecting to the parent comparison
  }
}
