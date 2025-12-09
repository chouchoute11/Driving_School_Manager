// Test setup and global configurations
process.env.NODE_ENV = 'test';
process.env.PORT = '4001';

// Suppress console logs during tests
const originalLog = console.log;
const originalError = console.error;
const originalWarn = console.warn;

beforeAll(() => {
  // Allow important logs through during testing
  global.testLogs = [];
  
  console.log = jest.fn((...args) => {
    global.testLogs.push({ level: 'log', args });
  });
  
  console.error = jest.fn((...args) => {
    global.testLogs.push({ level: 'error', args });
  });
  
  console.warn = jest.fn((...args) => {
    global.testLogs.push({ level: 'warn', args });
  });
});

afterAll(() => {
  console.log = originalLog;
  console.error = originalError;
  console.warn = originalWarn;
});

// Global timeout extension for API tests
jest.setTimeout(10000);

// Mock Date for consistent testing
global.testStartTime = Date.now();
