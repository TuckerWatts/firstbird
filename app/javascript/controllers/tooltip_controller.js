import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    content: String
  }

  connect() {
    this.element.setAttribute("title", this.element.dataset.tooltipContent)
  }
}