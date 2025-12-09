const request = require('supertest');
const { createTestApp } = require('./app-factory');

describe('Health Check Endpoints', () => {
  let app;

  beforeEach(() => {
    app = createTestApp();
  });

  describe('GET /health', () => {
    test('should return healthy status', async () => {
      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
      expect(response.body.timestamp).toBeDefined();
      expect(response.body.dataStore).toBe('in-memory');
    });

    test('should have valid timestamp', async () => {
      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      const timestamp = new Date(response.body.timestamp);
      expect(timestamp).toBeInstanceOf(Date);
      expect(timestamp.getTime()).toBeLessThanOrEqual(Date.now());
    });
  });

  describe('GET /ready', () => {
    test('should return ready status', async () => {
      const response = await request(app).get('/ready');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('ready');
      expect(response.body.ready).toBe(true);
    });
  });
});
