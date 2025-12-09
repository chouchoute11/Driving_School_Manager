const request = require('supertest');
const { createTestApp } = require('./app-factory');

describe('Lessons API Endpoints', () => {
  let app;

  beforeEach(() => {
    app = createTestApp();
  });

  describe('GET /api/lessons', () => {
    test('should return empty lessons array initially', async () => {
      const response = await request(app).get('/api/lessons');

      expect(response.status).toBe(200);
      expect(response.body.data).toEqual([]);
      expect(response.body.pagination).toEqual({
        page: 1,
        limit: 10,
        total: 0,
        pages: 0
      });
    });

    test('should return lessons with pagination', async () => {
      // Create multiple lessons
      for (let i = 0; i < 15; i++) {
        await request(app).post('/api/lessons').send({
          studentId: 1,
          instructorId: 1,
          date: '2025-12-10',
          duration: 60,
          status: 'scheduled'
        });
      }

      const response = await request(app)
        .get('/api/lessons')
        .query({ page: 1, limit: 10 });

      expect(response.status).toBe(200);
      expect(response.body.data).toHaveLength(10);
      expect(response.body.pagination.total).toBe(15);
      expect(response.body.pagination.pages).toBe(2);
    });

    test('should filter lessons by status', async () => {
      await request(app).post('/api/lessons').send({
        studentId: 1,
        instructorId: 1,
        date: '2025-12-10',
        duration: 60,
        status: 'scheduled'
      });

      await request(app).post('/api/lessons').send({
        studentId: 1,
        instructorId: 1,
        date: '2025-12-11',
        duration: 60,
        status: 'completed'
      });

      const response = await request(app)
        .get('/api/lessons')
        .query({ status: 'completed' });

      expect(response.status).toBe(200);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].status).toBe('completed');
    });
  });

  describe('POST /api/lessons', () => {
    test('should create a new lesson with valid data', async () => {
      const lessonData = {
        studentId: 1,
        instructorId: 1,
        date: '2025-12-10',
        duration: 60,
        status: 'scheduled',
        notes: 'Test lesson'
      };

      const response = await request(app)
        .post('/api/lessons')
        .send(lessonData);

      expect(response.status).toBe(201);
      expect(response.body).toMatchObject(lessonData);
      expect(response.body.id).toBeDefined();
      expect(response.body.createdAt).toBeDefined();
    });

    test('should return 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/api/lessons')
        .send({
          studentId: 1,
          date: '2025-12-10'
          // missing instructorId and duration
        });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Missing required fields');
    });

    test('should set default status to scheduled', async () => {
      const response = await request(app)
        .post('/api/lessons')
        .send({
          studentId: 1,
          instructorId: 1,
          date: '2025-12-10',
          duration: 60
        });

      expect(response.status).toBe(201);
      expect(response.body.status).toBe('scheduled');
    });
  });

  describe('PUT /api/lessons/:id', () => {
    test('should update an existing lesson', async () => {
      // Create a lesson
      const createResponse = await request(app)
        .post('/api/lessons')
        .send({
          studentId: 1,
          instructorId: 1,
          date: '2025-12-10',
          duration: 60,
          status: 'scheduled'
        });

      const lessonId = createResponse.body.id;

      // Update it
      const updateResponse = await request(app)
        .put(`/api/lessons/${lessonId}`)
        .send({ status: 'completed', notes: 'Lesson completed successfully' });

      expect(updateResponse.status).toBe(200);
      expect(updateResponse.body.status).toBe('completed');
      expect(updateResponse.body.notes).toBe('Lesson completed successfully');
    });

    test('should return 404 for non-existent lesson', async () => {
      const response = await request(app)
        .put('/api/lessons/999')
        .send({ status: 'completed' });

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Lesson not found');
    });
  });

  describe('DELETE /api/lessons/:id', () => {
    test('should delete an existing lesson', async () => {
      // Create a lesson
      const createResponse = await request(app)
        .post('/api/lessons')
        .send({
          studentId: 1,
          instructorId: 1,
          date: '2025-12-10',
          duration: 60
        });

      const lessonId = createResponse.body.id;

      // Delete it
      const deleteResponse = await request(app).delete(`/api/lessons/${lessonId}`);

      expect(deleteResponse.status).toBe(200);
      expect(deleteResponse.body.data.id).toBe(lessonId);

      // Verify it's deleted
      const getResponse = await request(app).get('/api/lessons');
      expect(getResponse.body.data).toHaveLength(0);
    });

    test('should return 404 when deleting non-existent lesson', async () => {
      const response = await request(app).delete('/api/lessons/999');

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Lesson not found');
    });
  });
});
