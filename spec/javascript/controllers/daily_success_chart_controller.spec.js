import { Application } from '@hotwired/stimulus';
import DailySuccessChartController from '../../../app/javascript/controllers/daily_success_chart_controller';

describe('DailySuccessChartController', () => {
  let application;
  let element;
  let controller;
  const testData = [
    { date: '2024-03-01', successful: 5, total: 10, rate: 50.0 },
    { date: '2024-03-02', successful: 8, total: 10, rate: 80.0 }
  ];

  beforeEach(() => {
    application = Application.start();
    application.register('daily-success-chart', DailySuccessChartController);

    element = document.createElement('div');
    element.setAttribute('data-controller', 'daily-success-chart');
    document.body.appendChild(element);

    const canvas = document.createElement('canvas');
    canvas.setAttribute('data-daily-success-chart-target', 'canvas');
    element.appendChild(canvas);

    element.setAttribute('data-daily-success-chart-historical-data-value', JSON.stringify(testData));
  });

  afterEach(() => {
    if (element.parentNode) {
      element.parentNode.removeChild(element);
    }
    application.stop();
  });

  it('initializes with historical data', () => {
    controller = application.getControllerForElementAndIdentifier(element, 'daily-success-chart');
    expect(controller.hasChartData).toBe(true);
    expect(controller.historicalDataValue).toHaveLength(2);
  });

  it('creates a chart when connected', () => {
    controller = application.getControllerForElementAndIdentifier(element, 'daily-success-chart');
    expect(controller.chart).toBeDefined();
  });

  it('destroys the chart when disconnected', () => {
    controller = application.getControllerForElementAndIdentifier(element, 'daily-success-chart');
    const destroySpy = jest.spyOn(controller.chart, 'destroy');
    
    controller.disconnect();
    expect(destroySpy).toHaveBeenCalled();
  });

  it('handles missing data gracefully', () => {
    element.removeAttribute('data-daily-success-chart-historical-data-value');
    controller = application.getControllerForElementAndIdentifier(element, 'daily-success-chart');
    
    // Force a reconnect to ensure the chart is reinitialized
    controller.disconnect();
    controller.connect();
    
    expect(controller.hasChartData).toBe(false);
    expect(controller.chart).toBeUndefined();
  });

  it('formats chart data correctly', () => {
    controller = application.getControllerForElementAndIdentifier(element, 'daily-success-chart');
    
    const mockChart = controller.chart;
    mockChart.data.labels = testData.map(d => d.date);
    mockChart.data.datasets[0].data = testData.map(d => d.rate);

    expect(mockChart.data.labels).toHaveLength(2);
    expect(mockChart.data.datasets[0].data).toHaveLength(2);
    expect(mockChart.data.datasets[0].data[0]).toBe(50.0);
    expect(mockChart.data.datasets[0].data[1]).toBe(80.0);
  });
}); 