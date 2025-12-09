module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: [
    'index.js',
    'tests/**/*.js',
    '!node_modules/**',
    '!coverage/**',
    '!dist/**',
    '!**/node_modules/**'
  ],
  coverageThreshold: {
    global: {
      branches: 15,
      functions: 15,
      lines: 15,
      statements: 15
    }
  },
  coverageReporters: ['text', 'text-summary', 'html', 'lcov', 'json'],
  testTimeout: 10000,
  verbose: true,
  bail: false,
  errorOnDeprecated: true,
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true,
  setupFilesAfterEnv: ['<rootDir>/tests/setup.js'],
  forceExit: true
};
