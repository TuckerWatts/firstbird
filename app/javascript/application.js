// app/javascript/application.js

// Import Turbo, Stimulus, and any JS needed in your app
import "@hotwired/turbo-rails"
import "controllers"

// Import Chart.js for data visualizations
import { Chart, registerables } from "chart.js"
Chart.register(...registerables)