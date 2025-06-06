import '@testing-library/jest-dom'

// Mock Chart.js
jest.mock('chart.js', () => {
  const mockChart = jest.fn().mockImplementation(() => ({
    destroy: jest.fn(),
    data: {
      labels: [],
      datasets: [{
        data: []
      }]
    }
  }));

  mockChart.register = jest.fn();
  mockChart.registerables = [];

  return {
    Chart: mockChart,
    registerables: []
  };
});

// Mock ResizeObserver
global.ResizeObserver = class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
};

// Setup DOM environment
if (typeof window !== 'undefined') {
  window.ResizeObserver = jest.fn().mockImplementation(() => ({
    observe: jest.fn(),
    unobserve: jest.fn(),
    disconnect: jest.fn(),
  }))
} 