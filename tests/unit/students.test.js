const request = require('supertest');
const { createTestApp } = require('./app-factory');

describe('Students API Endpoints', () => {
  let app;

  beforeEach(() => {
    app = createTestApp();
  });

  describe('GET /api/students', () => {
    test('should return empty students array initially', async () => {
      const response = await request(app).get('/api/students');

      expect(response.status).toBe(200);
      expect(response.body.data).toEqual([]);
      expect(response.body.pagination.total).toBe(0);
    });

    test('should return students with pagination', async () => {
      // Create multiple students
      for (let i = 0; i < 12; i++) {
        await request(app).post('/api/students').send({
          name: `Student ${i}`,
          email: `student${i}@test.com`,
          phone: '1234567890'
        });
      }

      const response = await request(app)
        .get('/api/students')
        .query({ page: 1, limit: 10 });

      expect(response.status).toBe(200);
      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.total).toBe(12);
      expect(response.body.pagination.pages).toBe(2);
    });
  });

  describe('POST /api/students', () => {
    test('should create a new student with valid data', async () => {
      const studentData = {
        name: 'John Doe',
        email: 'john@test.com',
        phone: '1234567890',
        licenseStatus: 'pending'
      };

      const response = await request(app)
        .post('/api/students')
        .send(studentData);

      expect(response.status).toBe(201);
      expect(response.body.name).toBe(studentData.name);
      expect(response.body.email).toBe(studentData.email);
      expect(response.body.id).toBeDefined();
      expect(response.body.lessonsCompleted).toBe(0);
    });

    test('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/students')
        .send({
          name: 'John Doe'
          // missing email
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Missing required fields');
    });

    test('should set default values for optional fields', async () => {
      const response = await request(app)
        .post('/api/students')
        .send({
          name: 'Jane Doe',
          email: 'jane@test.com'
        });

      expect(response.status).toBe(201);
      expect(response.body.licenseStatus).toBe('pending');
      expect(response.body.lessonsCompleted).toBe(0);
      expect(response.body.totalCost).toBe(0);
    });
  });
});
