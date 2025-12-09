const express = require('express');
const path = require('path');

// Create a test app (mirrors main index.js structure)
function createTestApp() {
  const app = express();
  
  // In-memory store
  const store = {
    students: [],
    instructors: [],
    lessons: [],
    reports: [],
    nextIds: {
      students: 1,
      instructors: 1,
      lessons: 1,
      reports: 1
    }
  };

  // Middleware
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));
  app.use(express.static('public'));

  // Health check
  app.get('/health', (req, res) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      dataStore: 'in-memory'
    });
  });

  // Ready check
  app.get('/ready', (req, res) => {
    res.json({ status: 'ready', ready: true });
  });

  // Home
  app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../../public/index.html'));
  });

  // ============================================
  // LESSONS ENDPOINTS
  // ============================================

  app.get('/api/lessons', (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const status = req.query.status;

    let lessons = store.lessons;
    if (status) {
      lessons = lessons.filter(l => l.status === status);
    }

    const total = lessons.length;
    const start = (page - 1) * limit;
    const paginatedLessons = lessons.slice(start, start + limit);

    res.json({
      data: paginatedLessons,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) }
    });
  });

  app.post('/api/lessons', (req, res) => {
    const { studentId, instructorId, date, duration, status, notes } = req.body;

    if (!studentId || !instructorId || !date || !duration) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const newLesson = {
      id: store.nextIds.lessons++,
      studentId,
      instructorId,
      date,
      duration,
      status: status || 'scheduled',
      notes: notes || '',
      createdAt: new Date().toISOString()
    };

    store.lessons.push(newLesson);
    res.status(201).json(newLesson);
  });

  app.put('/api/lessons/:id', (req, res) => {
    const id = parseInt(req.params.id);
    const lesson = store.lessons.find(l => l.id === id);

    if (!lesson) {
      return res.status(404).json({ error: 'Lesson not found' });
    }

    Object.assign(lesson, req.body);
    res.json(lesson);
  });

  app.delete('/api/lessons/:id', (req, res) => {
    const id = parseInt(req.params.id);
    const index = store.lessons.findIndex(l => l.id === id);

    if (index === -1) {
      return res.status(404).json({ error: 'Lesson not found' });
    }

    const deleted = store.lessons.splice(index, 1);
    res.json({ message: 'Lesson deleted', data: deleted[0] });
  });

  // ============================================
  // STUDENTS ENDPOINTS
  // ============================================

  app.get('/api/students', (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;

    const total = store.students.length;
    const start = (page - 1) * limit;
    const paginatedStudents = store.students.slice(start, start + limit);

    res.json({
      data: paginatedStudents,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) }
    });
  });

  app.post('/api/students', (req, res) => {
    const { name, email, phone, licenseStatus } = req.body;

    if (!name || !email) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const newStudent = {
      id: store.nextIds.students++,
      name,
      email,
      phone: phone || '',
      licenseStatus: licenseStatus || 'pending',
      lessonsCompleted: 0,
      totalCost: 0,
      createdAt: new Date().toISOString()
    };

    store.students.push(newStudent);
    res.status(201).json(newStudent);
  });

  // ============================================
  // INSTRUCTORS ENDPOINTS
  // ============================================

  app.get('/api/instructors', (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;

    const total = store.instructors.length;
    const start = (page - 1) * limit;
    const paginatedInstructors = store.instructors.slice(start, start + limit);

    res.json({
      data: paginatedInstructors,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) }
    });
  });

  app.post('/api/instructors', (req, res) => {
    const { name, email, phone, specialization } = req.body;

    if (!name || !email) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const newInstructor = {
      id: store.nextIds.instructors++,
      name,
      email,
      phone: phone || '',
      specialization: specialization || 'standard',
      lessonsGiven: 0,
      rating: 0,
      createdAt: new Date().toISOString()
    };

    store.instructors.push(newInstructor);
    res.status(201).json(newInstructor);
  });

  // ============================================
  // REPORTS ENDPOINTS
  // ============================================

  app.get('/api/reports', (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;

    const total = store.reports.length;
    const start = (page - 1) * limit;
    const paginatedReports = store.reports.slice(start, start + limit);

    res.json({
      data: paginatedReports,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) }
    });
  });

  app.post('/api/reports', (req, res) => {
    const { type, startDate, endDate, format } = req.body;

    if (!type || !startDate || !endDate) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const newReport = {
      id: store.nextIds.reports++,
      type,
      startDate,
      endDate,
      format: format || 'json',
      status: 'generated',
      generatedAt: new Date().toISOString()
    };

    store.reports.push(newReport);
    res.status(201).json(newReport);
  });

  return app;
}

module.exports = { createTestApp };
