const request = require('supertest');
const { createTestApp } = require('../unit/app-factory');

describe('Integration Tests - Full Workflows', () => {
  let app;

  beforeEach(() => {
    app = createTestApp();
  });

  describe('Complete Lesson Booking Workflow', () => {
    test('should create student, instructor, and schedule lesson', async () => {
      // Step 1: Create a student
      const studentRes = await request(app)
        .post('/api/students')
        .send({
          name: 'Alice Johnson',
          email: 'alice@test.com',
          phone: '5551234567'
        });

      expect(studentRes.status).toBe(201);
      const studentId = studentRes.body.id;

      // Step 2: Create an instructor
      const instructorRes = await request(app)
        .post('/api/instructors')
        .send({
          name: 'Bob Smith',
          email: 'bob@test.com',
          phone: '5559876543',
          specialization: 'advanced'
        });

      expect(instructorRes.status).toBe(201);
      const instructorId = instructorRes.body.id;

      // Step 3: Schedule a lesson
      const lessonRes = await request(app)
        .post('/api/lessons')
        .send({
          studentId,
          instructorId,
          date: '2025-12-15',
          duration: 90,
          notes: 'Advanced driving techniques'
        });

      expect(lessonRes.status).toBe(201);
      expect(lessonRes.body.studentId).toBe(studentId);
      expect(lessonRes.body.instructorId).toBe(instructorId);
      expect(lessonRes.body.status).toBe('scheduled');

      // Step 4: Verify lesson appears in list
      const lessonsRes = await request(app).get('/api/lessons');
      expect(lessonsRes.status).toBe(200);
      expect(lessonsRes.body.data).toHaveLength(1);
      expect(lessonsRes.body.data[0].studentId).toBe(studentId);
    });

    test('should complete lesson workflow: schedule -> execute -> mark complete', async () => {
      // Create student and instructor
      const student = await request(app)
        .post('/api/students')
        .send({ name: 'Charlie', email: 'charlie@test.com' });

      const instructor = await request(app)
        .post('/api/instructors')
        .send({ name: 'Diana', email: 'diana@test.com' });

      // Schedule lesson
      const lesson = await request(app)
        .post('/api/lessons')
        .send({
          studentId: student.body.id,
          instructorId: instructor.body.id,
          date: '2025-12-20',
          duration: 60,
          status: 'scheduled'
        });

      const lessonId = lesson.body.id;

      // Verify initial status
      expect(lesson.body.status).toBe('scheduled');

      // Mark as in-progress
      const inProgressRes = await request(app)
        .put(`/api/lessons/${lessonId}`)
        .send({ status: 'in-progress' });

      expect(inProgressRes.status).toBe(200);
      expect(inProgressRes.body.status).toBe('in-progress');

      // Mark as completed with notes
      const completedRes = await request(app)
        .put(`/api/lessons/${lessonId}`)
        .send({
          status: 'completed',
          notes: 'Lesson went well, student made good progress'
        });

      expect(completedRes.status).toBe(200);
      expect(completedRes.body.status).toBe('completed');
      expect(completedRes.body.notes).toContain('progress');

      // Verify in lesson list
      const lessonsRes = await request(app)
        .get('/api/lessons')
        .query({ status: 'completed' });

      expect(lessonsRes.body.data).toHaveLength(1);
      expect(lessonsRes.body.data[0].id).toBe(lessonId);
    });
  });

  describe('Report Generation Workflow', () => {
    test('should generate report after lessons completed', async () => {
      // Create multiple lessons
      for (let i = 0; i < 3; i++) {
        await request(app)
          .post('/api/students')
          .send({ name: `Student ${i}`, email: `s${i}@test.com` });

        await request(app)
          .post('/api/instructors')
          .send({ name: `Instructor ${i}`, email: `i${i}@test.com` });

        await request(app)
          .post('/api/lessons')
          .send({
            studentId: i + 1,
            instructorId: i + 1,
            date: '2025-12-10',
            duration: 60,
            status: 'completed'
          });
      }

      // Generate report
      const reportRes = await request(app)
        .post('/api/reports')
        .send({
          type: 'attendance',
          startDate: '2025-12-01',
          endDate: '2025-12-31',
          format: 'json'
        });

      expect(reportRes.status).toBe(201);
      expect(reportRes.body.type).toBe('attendance');
      expect(reportRes.body.status).toBe('generated');

      // Verify report in list
      const reportsRes = await request(app).get('/api/reports');
      expect(reportsRes.body.data).toHaveLength(1);
    });
  });

  describe('Data Consistency Workflow', () => {
    test('should maintain data consistency across operations', async () => {
      // Create 5 students
      const students = [];
      for (let i = 0; i < 5; i++) {
        const res = await request(app)
          .post('/api/students')
          .send({ name: `Student ${i}`, email: `student${i}@test.com` });
        students.push(res.body);
      }

      // Verify count
      let listRes = await request(app).get('/api/students');
      expect(listRes.body.pagination.total).toBe(5);

      // Delete one student (by not creating lessons for one)
      // Create lessons for first 4
      for (let i = 0; i < 4; i++) {
        await request(app)
          .post('/api/instructors')
          .send({ name: `Instructor ${i}`, email: `instructor${i}@test.com` });

        await request(app)
          .post('/api/lessons')
          .send({
            studentId: students[i].id,
            instructorId: i + 1,
            date: '2025-12-15',
            duration: 60
          });
      }

      // Verify 4 lessons
      listRes = await request(app).get('/api/lessons');
      expect(listRes.body.pagination.total).toBe(4);

      // Verify 5 students still exist
      listRes = await request(app).get('/api/students');
      expect(listRes.body.pagination.total).toBe(5);
    });
  });

  describe('Error Recovery Workflow', () => {
    test('should handle cascading errors gracefully', async () => {
      // Try to create lesson without student
      const lessonRes = await request(app)
        .post('/api/lessons')
        .send({
          instructorId: 1,
          date: '2025-12-15',
          duration: 60
          // missing studentId
        });

      expect(lessonRes.status).toBe(400);

      // Verify no lesson was created
      let listRes = await request(app).get('/api/lessons');
      expect(listRes.body.data).toHaveLength(0);

      // Now create properly
      const student = await request(app)
        .post('/api/students')
        .send({ name: 'Test', email: 'test@test.com' });

      const instructor = await request(app)
        .post('/api/instructors')
        .send({ name: 'Test', email: 'test.inst@test.com' });

      const validLesson = await request(app)
        .post('/api/lessons')
        .send({
          studentId: student.body.id,
          instructorId: instructor.body.id,
          date: '2025-12-15',
          duration: 60
        });

      expect(validLesson.status).toBe(201);

      // Verify now we have 1 lesson
      listRes = await request(app).get('/api/lessons');
      expect(listRes.body.data).toHaveLength(1);
    });
  });
});
