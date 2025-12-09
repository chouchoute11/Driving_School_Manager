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
      branches: 50,
      functions: 50,
      lines: 50,
      statements: 50
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
