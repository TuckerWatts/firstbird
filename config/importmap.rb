# config/importmap.rb
pin "application", preload: true

# Turbo & Stimulus
pin "@hotwired/turbo-rails",    to: "turbo.min.js",    preload: true
pin "@hotwired/stimulus",       to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# Pin all controllers in app/javascript/controllers
pin_all_from "app/javascript/controllers", under: "controllers"

# Chart.js & dependencies
pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.4.1/dist/chart.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"