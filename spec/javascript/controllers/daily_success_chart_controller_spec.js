import { Application } from "@hotwired/stimulus"
import DailySuccessChartController from "controllers/daily_success_chart_controller"

// Mock Chart.js
jest.mock('chart.js', () => ({
  Chart: jest.fn().mockImplementation(() => ({
    destroy: jest.fn(),
    data: {
      labels: [],
      datasets: [{ data: [] }]
    },
    config: {
      type: 'line'
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        y: {
          min: 0,
          max: 100,
          title: { text: 'Success Rate' }
        }
      },
      plugins: {
        tooltip: {
          callbacks: {
            label: (context) => `Success Rate: ${context.parsed.y.toFixed(2)}%`
          }
        }
      }
    }
  }))
}))

describe("DailySuccessChartController", () => {
  let application
  let controller
  let element
  let canvas

  beforeEach(() => {
    // Setup DOM
    document.body.innerHTML = `
      <div data-controller="daily-success-chart">
        <canvas data-daily-success-chart-target="canvas"
                data-daily-success-chart-labels='["2024-01-01", "2024-01-02"]'
                data-daily-success-chart-values='[75.5, 82.3]'></canvas>
      </div>
    `

    // Initialize Stimulus application
    application = Application.start()
    application.register("daily-success-chart", DailySuccessChartController)

    // Get references to elements
    element = document.querySelector('[data-controller="daily-success-chart"]')
    canvas = element.querySelector('canvas')
    controller = application.getControllerForElementAndIdentifier(element, "daily-success-chart")

    // Clear any previous mock calls
    jest.clearAllMocks()
  })

  afterEach(() => {
    // Cleanup
    document.body.innerHTML = ''
    jest.clearAllMocks()
  })

  describe("initialization", () => {
    it("connects to the DOM", () => {
      expect(controller.canvasTarget).toBeDefined()
      expect(controller.canvasTarget).toBe(canvas)
    })

    it("creates a chart with the provided data", () => {
      expect(controller.chart).toBeDefined()
      expect(controller.hasChartData).toBe(true)
    })

    it("parses data attributes correctly", () => {
      const labels = JSON.parse(canvas.dataset.dailySuccessChartLabels)
      const values = JSON.parse(canvas.dataset.dailySuccessChartValues)
      
      expect(labels).toEqual(["2024-01-01", "2024-01-02"])
      expect(values).toEqual([75.5, 82.3])
    })
  })

  describe("chart configuration", () => {
    it("sets up correct chart type and options", () => {
      expect(controller.chart.config.type).toBe('line')
      expect(controller.chart.options.responsive).toBe(true)
      expect(controller.chart.options.maintainAspectRatio).toBe(false)
    })

    it("configures proper axes", () => {
      const yAxis = controller.chart.options.scales.y
      expect(yAxis.min).toBe(0)
      expect(yAxis.max).toBe(100)
      expect(yAxis.title.text).toBe('Success Rate')
    })

    it("sets up tooltips correctly", () => {
      const tooltip = controller.chart.options.plugins.tooltip
      expect(tooltip.callbacks.label).toBeDefined()
      
      const context = { parsed: { y: 75.5 } }
      const label = tooltip.callbacks.label(context)
      expect(label).toBe('Success Rate: 75.50%')
    })
  })

  describe("cleanup", () => {
    it("destroys the chart when disconnected", () => {
      const destroySpy = jest.spyOn(controller.chart, 'destroy')
      controller.disconnect()
      expect(destroySpy).toHaveBeenCalled()
    })
  })

  describe("error handling", () => {
    it("handles missing data gracefully", () => {
      document.body.innerHTML = `
        <div data-controller="daily-success-chart">
          <canvas data-daily-success-chart-target="canvas"></canvas>
        </div>
      `
      
      element = document.querySelector('[data-controller="daily-success-chart"]')
      controller = application.getControllerForElementAndIdentifier(element, "daily-success-chart")
      
      expect(controller.hasChartData).toBe(false)
      expect(controller.chart).toBeUndefined()
    })

    it("handles invalid JSON data gracefully", () => {
      document.body.innerHTML = `
        <div data-controller="daily-success-chart">
          <canvas data-daily-success-chart-target="canvas"
                  data-daily-success-chart-labels='invalid'
                  data-daily-success-chart-values='invalid'></canvas>
        </div>
      `
      
      element = document.querySelector('[data-controller="daily-success-chart"]')
      controller = application.getControllerForElementAndIdentifier(element, "daily-success-chart")
      
      expect(controller.hasChartData).toBe(false)
      expect(controller.chart).toBeUndefined()
    })
  })
}) 