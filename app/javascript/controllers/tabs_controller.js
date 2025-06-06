import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "panel", "select"]

  connect() {
    // Make sure the active tab is highlighted on load
    this.switchTab(0)
  }

  switch(event) {
    const clickedTab = event.currentTarget
    const index = this.tabTargets.indexOf(clickedTab)
    this.switchTab(index)
  }

  selectChange(event) {
    const select = event.currentTarget
    const index = select.selectedIndex
    this.switchTab(index)
  }

  switchTab(index) {
    // Activate the correct tab
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.add("border-indigo-500", "text-indigo-600")
        tab.classList.remove("border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700")
        tab.setAttribute("aria-current", "page")
      } else {
        tab.classList.remove("border-indigo-500", "text-indigo-600")
        tab.classList.add("border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700")
        tab.removeAttribute("aria-current")
      }
    })

    // Show the correct panel
    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove("hidden")
        
        // Ensure the Turbo frame inside this panel is loaded
        const frame = panel.querySelector('turbo-frame')
        if (frame) {
          // Force reload the frame when switching to this tab
          frame.setAttribute('loading', 'eager')
          frame.reload()
        }
      } else {
        panel.classList.add("hidden")
      }
    })

    // Update select if it exists
    if (this.hasSelectTarget) {
      this.selectTarget.selectedIndex = index
    }
  }
} 