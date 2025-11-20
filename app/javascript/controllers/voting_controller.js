import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["leftForm", "rightForm", "leftKill", "rightKill"]
  
  connect() {
    this.boundKeyHandler = this.handleKeyPress.bind(this)
    document.addEventListener("keydown", this.boundKeyHandler)
  }
  
  disconnect() {
    document.removeEventListener("keydown", this.boundKeyHandler)
  }
  
  handleKeyPress(event) {
    // Ignore if user is typing in an input field
    if (event.target.matches("input, textarea, select")) {
      return
    }
    
    switch(event.key) {
      case "ArrowLeft":
        event.preventDefault()
        this.voteLeft()
        break
      case "ArrowRight":
        event.preventDefault()
        this.voteRight()
        break
      case "k":
      case "K":
        event.preventDefault()
        // Focus determines which image to kill
        // For now, default to left image
        this.killLeft()
        break
      case "n":
      case "N":
        event.preventDefault()
        this.skipPair()
        break
    }
  }
  
  voteLeft() {
    if (this.hasLeftFormTarget) {
      this.leftFormTarget.requestSubmit()
    }
  }
  
  voteRight() {
    if (this.hasRightFormTarget) {
      this.rightFormTarget.requestSubmit()
    }
  }
  
  killLeft() {
    if (this.hasLeftKillTarget) {
      this.leftKillTarget.requestSubmit()
    }
  }
  
  killRight() {
    if (this.hasRightKillTarget) {
      this.rightKillTarget.requestSubmit()
    }
  }
  
  skipPair() {
    // Reload the page to get a new pair
    window.location.reload()
  }
}
