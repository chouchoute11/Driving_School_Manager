const request = require('supertest');
const { createTestApp } = require('./app-factory');

describe('Instructors API Endpoints', () => {
  let app;

  beforeEach(() => {
    app = createTestApp();
  });

  describe('GET /api/instructors', () => {
    test('should return empty instructors array initially', async () => {
      const response = await request(app).get('/api/instructors');

      expect(response.status).toBe(200);
      expect(response.body.data).toEqual([]);
      expect(response.body.pagination.total).toBe(0);
    });

    test('should return instructors with pagination', async () => {
      // Create multiple instructors
      for (let i = 0; i < 12; i++) {
        await request(app).post('/api/instructors').send({
          name: `Instructor ${i}`,
          email: `instructor${i}@test.com`,
          phone: '1234567890'
        });
      }

      const response = await request(app)
        .get('/api/instructors')
        .query({ page: 1, limit: 10 });

      expect(response.status).toBe(200);
      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.total).toBe(12);
    });
  });

  describe('POST /api/instructors', () => {
    test('should create a new instructor with valid data', async () => {
      const instructorData = {
        name: 'John Smith',
        email: 'john.smith@test.com',
        phone: '1234567890',
        specialization: 'advanced'
      };

      const response = await request(app)
        .post('/api/instructors')
        .send(instructorData);

      expect(response.status).toBe(201);
      expect(response.body.name).toBe(instructorData.name);
      expect(response.body.email).toBe(instructorData.email);
      expect(response.body.specialization).toBe('advanced');
      expect(response.body.id).toBeDefined();
    });

    test('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/instructors')
        .send({
          name: 'John Smith'
          // missing email
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Missing required fields');
    });

    test('should set default values for optional fields', async () => {
      const response = await request(app)
        .post('/api/instructors')
        .send({
          name: 'Jane Smith',
          email: 'jane.smith@test.com'
        });

      expect(response.status).toBe(201);
      expect(response.body.specialization).toBe('standard');
      expect(response.body.lessonsGiven).toBe(0);
      expect(response.body.rating).toBe(0);
    });
  });
});
