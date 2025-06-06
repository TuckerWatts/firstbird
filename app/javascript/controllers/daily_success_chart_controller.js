// app/javascript/controllers/daily_success_chart_controller.js
// Minimal Stimulus controller leveraging Chart.js for data visualization.
// If Chart.js is not installed, add it to your project (e.g., via yarn or npm).
import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from 'chart.js'

Chart.register(...registerables);

// Connects to data-controller="daily-success-chart"
export default class extends Controller {
  static targets = ["canvas"]
  static values = { historicalData: Array }

  connect() {
    if (this.hasChartData) {
      this.initializeChart();
    }
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = undefined;
    }
  }

  get hasChartData() {
    return this.historicalDataValue && this.historicalDataValue.length > 0;
  }

  initializeChart() {
    if (!this.canvasTarget || !this.hasChartData) {
      this.chart = undefined;
      return;
    }

    const data = {
      labels: this.historicalDataValue.map(d => d.date),
      datasets: [{
        label: 'Success Rate (%)',
        data: this.historicalDataValue.map(d => d.rate),
        borderColor: 'rgb(75, 192, 192)',
        tension: 0.1
      }]
    };

    const options = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        tooltip: {
          callbacks: {
            label: (context) => {
              const dataPoint = this.historicalDataValue[context.dataIndex];
              return `Success Rate: ${dataPoint.rate}% (${dataPoint.successful}/${dataPoint.total})`;
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          max: 100,
          title: {
            display: true,
            text: 'Success Rate (%)'
          }
        },
        x: {
          title: {
            display: true,
            text: 'Date'
          }
        }
      }
    };

    this.chart = new Chart(this.canvasTarget, {
      type: 'line',
      data: data,
      options: options
    });
  }
}