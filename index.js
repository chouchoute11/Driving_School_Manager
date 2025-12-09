const express = require('express');
const path = require('path');
const app = express();

// ============================================
// CONFIGURATION & ENVIRONMENT VALIDATION
// ============================================

// Validate required environment variables
const requiredEnvVars = [];
const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);
if (missingEnvVars.length > 0) {
  console.error(`[ERROR] Missing required environment variables: ${missingEnvVars.join(', ')}`);
  process.exit(1);
}

// Structured logging helper
const logger = {
  info: (message, metadata = {}) => {
    console.log(JSON.stringify({ level: 'INFO', timestamp: new Date().toISOString(), message, ...metadata }));
  },
  error: (message, error = null, metadata = {}) => {
    console.error(JSON.stringify({ level: 'ERROR', timestamp: new Date().toISOString(), message, error: error?.message, ...metadata }));
  },
  warn: (message, metadata = {}) => {
    console.warn(JSON.stringify({ level: 'WARN', timestamp: new Date().toISOString(), message, ...metadata }));
  }
};

// Service Level Objectives (SLOs) Tracking
const slos = {
  targetUptime: 0.99, // 99% uptime
  targetLatency: 200, // 200ms p95 latency
  targetErrorRate: 0.01, // 1% error rate
  errorBudget: 0.01, // 1% error budget
  metrics: {
    startTime: Date.now(),
    totalRequests: 0,
    totalErrors: 0,
    errorBudgetUsed: 0
  }
};

// In-memory data store (replaces database)
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

// Request metrics middleware
app.use((req, res, next) => {
  const startTime = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    slos.metrics.totalRequests++;
    if (res.statusCode >= 400) {
      slos.metrics.totalErrors++;
    }
    logger.info('Request completed', { 
      method: req.method, 
      path: req.path, 
      status: res.statusCode, 
      duration: `${duration}ms` 
    });
  });
  next();
});

// Initialize in-memory store with sample data
async function initDB() {
  logger.info('In-memory store initialized (localStorage mode)');
  return;
}

// ============================================
// HEALTH CHECK & MONITORING ENDPOINTS
// ============================================

// Health check endpoint (for container orchestration)
app.get('/health', (req, res) => {
  const healthStatus = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: Math.floor((Date.now() - slos.metrics.startTime) / 1000),
    dataStore: 'in-memory',
    slos: {
      errorRate: (slos.metrics.totalErrors / Math.max(slos.metrics.totalRequests, 1)).toFixed(4),
      errorBudgetRemaining: (slos.errorBudget - slos.metrics.errorBudgetUsed).toFixed(4),
      targetUptime: `${slos.targetUptime * 100}%`,
      targetLatency: `${slos.targetLatency}ms`
    }
  };
  
  res.status(200).json(healthStatus);
});

// Ready check endpoint (for Kubernetes)
app.get('/ready', async (req, res) => {
  res.status(200).json({ ready: true, timestamp: new Date().toISOString() });
});

// ============================================
// CORE APPLICATION ROUTES
// ============================================

// Home page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ============================================
// LESSON MANAGEMENT ENDPOINTS
// ============================================

// GET all lessons with filtering and pagination
app.get('/api/lessons', async (req, res) => {
  try {
    const { student_id, instructor_id, status, limit = 50, offset = 0 } = req.query;
    let filtered = store.lessons;

    if (student_id) {
      filtered = filtered.filter(l => l.student_id == student_id);
    }
    if (instructor_id) {
      filtered = filtered.filter(l => l.instructor_id == instructor_id);
    }
    if (status) {
      filtered = filtered.filter(l => l.status === status);
    }

    const sorted = filtered.sort((a, b) => new Date(b.lesson_date) - new Date(a.lesson_date));
    const offset_int = parseInt(offset);
    const limit_int = parseInt(limit);
    const paginated = sorted.slice(offset_int, offset_int + limit_int);

    res.json({ success: true, data: paginated, count: paginated.length, total: sorted.length });
  } catch (error) {
    logger.error('Error fetching lessons', error);
    res.status(500).json({ error: 'Failed to fetch lessons', details: error.message });
  }
});

// POST new lesson
app.post('/api/lessons', async (req, res) => {
  const { student_id, instructor_id, lesson_date, duration, notes } = req.body;

  // Input validation
  if (!student_id || !instructor_id || !lesson_date || !duration) {
    return res.status(400).json({ 
      error: 'Missing required fields: student_id, instructor_id, lesson_date, duration' 
    });
  }

  try {
    const lesson = {
      id: store.nextIds.lessons++,
      student_id: parseInt(student_id),
      instructor_id: parseInt(instructor_id),
      lesson_date,
      duration: parseInt(duration),
      status: 'scheduled',
      notes: notes || null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    store.lessons.push(lesson);
    logger.info('Lesson created', { lesson_id: lesson.id, student_id, instructor_id });
    res.status(201).json({
      success: true,
      id: lesson.id,
      message: 'Lesson scheduled successfully'
    });
  } catch (error) {
    logger.error('Error creating lesson', error);
    res.status(500).json({ error: 'Failed to create lesson', details: error.message });
  }
});

// PUT update lesson
app.put('/api/lessons/:id', async (req, res) => {
  const { id } = req.params;
  const { lesson_date, duration, status, notes } = req.body;

  try {
    const lesson = store.lessons.find(l => l.id == id);

    if (!lesson) {
      return res.status(404).json({ error: 'Lesson not found' });
    }

    if (lesson_date) lesson.lesson_date = lesson_date;
    if (duration) lesson.duration = parseInt(duration);
    if (status) lesson.status = status;
    if (notes !== undefined) lesson.notes = notes;
    lesson.updated_at = new Date().toISOString();

    logger.info('Lesson updated', { lesson_id: id });
    res.json({ success: true, message: 'Lesson updated successfully' });
  } catch (error) {
    logger.error('Error updating lesson', error);
    res.status(500).json({ error: 'Failed to update lesson', details: error.message });
  }
});

// DELETE lesson
app.delete('/api/lessons/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const index = store.lessons.findIndex(l => l.id == id);

    if (index === -1) {
      return res.status(404).json({ error: 'Lesson not found' });
    }

    store.lessons.splice(index, 1);
    logger.info('Lesson deleted', { lesson_id: id });
    res.json({ success: true, message: 'Lesson deleted successfully' });
  } catch (error) {
    logger.error('Error deleting lesson', error);
    res.status(500).json({ error: 'Failed to delete lesson', details: error.message });
  }
});

// ============================================
// STUDENT MANAGEMENT ENDPOINTS
// ============================================

// GET all students
app.get('/api/students', async (req, res) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;
    let filtered = store.students;

    if (status) {
      filtered = filtered.filter(s => s.status === status);
    }

    const sorted = filtered.sort((a, b) => a.first_name.localeCompare(b.first_name));
    const offset_int = parseInt(offset);
    const limit_int = parseInt(limit);
    const paginated = sorted.slice(offset_int, offset_int + limit_int);

    res.json({ success: true, data: paginated, count: paginated.length, total: sorted.length });
  } catch (error) {
    logger.error('Error fetching students', error);
    res.status(500).json({ error: 'Failed to fetch students', details: error.message });
  }
});

// POST new student
app.post('/api/students', async (req, res) => {
  const { first_name, last_name, email, phone, license_class } = req.body;

  if (!first_name || !last_name) {
    return res.status(400).json({ error: 'First name and last name are required' });
  }

  try {
    const student = {
      id: store.nextIds.students++,
      first_name,
      last_name,
      email: email || null,
      phone: phone || null,
      license_class: license_class || null,
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    store.students.push(student);
    logger.info('Student created', { student_id: student.id, first_name, last_name });
    res.status(201).json({
      success: true,
      id: student.id,
      message: 'Student registered successfully'
    });
  } catch (error) {
    logger.error('Error creating student', error);
    res.status(500).json({ error: 'Failed to create student', details: error.message });
  }
});

// ============================================
// INSTRUCTOR MANAGEMENT ENDPOINTS
// ============================================

// GET all instructors
app.get('/api/instructors', async (req, res) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;
    let filtered = store.instructors;

    if (status) {
      filtered = filtered.filter(i => i.status === status);
    }

    const sorted = filtered.sort((a, b) => a.first_name.localeCompare(b.first_name));
    const offset_int = parseInt(offset);
    const limit_int = parseInt(limit);
    const paginated = sorted.slice(offset_int, offset_int + limit_int);

    res.json({ success: true, data: paginated, count: paginated.length, total: sorted.length });
  } catch (error) {
    logger.error('Error fetching instructors', error);
    res.status(500).json({ error: 'Failed to fetch instructors', details: error.message });
  }
});

// POST new instructor
app.post('/api/instructors', async (req, res) => {
  const { first_name, last_name, email, phone, license_number } = req.body;

  if (!first_name || !last_name) {
    return res.status(400).json({ error: 'First name and last name are required' });
  }

  try {
    const instructor = {
      id: store.nextIds.instructors++,
      first_name,
      last_name,
      email: email || null,
      phone: phone || null,
      license_number: license_number || null,
      status: 'active',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    store.instructors.push(instructor);
    logger.info('Instructor created', { instructor_id: instructor.id, first_name, last_name });
    res.status(201).json({
      success: true,
      id: instructor.id,
      message: 'Instructor registered successfully'
    });
  } catch (error) {
    logger.error('Error creating instructor', error);
    res.status(500).json({ error: 'Failed to create instructor', details: error.message });
  }
});

// ============================================
// REPORTS ENDPOINTS
// ============================================

// GET reports with filters
app.get('/api/reports', async (req, res) => {
  try {
    const { type, student_id, period_start, period_end } = req.query;
    let filtered = store.reports;

    if (type) {
      filtered = filtered.filter(r => r.type === type);
    }
    if (student_id) {
      filtered = filtered.filter(r => r.student_id == student_id);
    }
    if (period_start) {
      filtered = filtered.filter(r => new Date(r.period_start) >= new Date(period_start));
    }
    if (period_end) {
      filtered = filtered.filter(r => new Date(r.period_end) <= new Date(period_end));
    }

    const sorted = filtered.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    res.json({ success: true, data: sorted, count: sorted.length });
  } catch (error) {
    logger.error('Error fetching reports', error);
    res.status(500).json({ error: 'Failed to fetch reports', details: error.message });
  }
});

// POST generate report
app.post('/api/reports', async (req, res) => {
  const { type, student_id, period_start, period_end, content } = req.body;

  if (!type || !period_start || !period_end) {
    return res.status(400).json({ 
      error: 'Missing required fields: type, period_start, period_end' 
    });
  }

  try {
    const report = {
      id: store.nextIds.reports++,
      type,
      student_id: student_id ? parseInt(student_id) : null,
      period_start,
      period_end,
      content: content || {},
      created_at: new Date().toISOString()
    };
    store.reports.push(report);
    logger.info('Report generated', { report_id: report.id, type, student_id });
    res.status(201).json({
      success: true,
      id: report.id,
      message: 'Report generated successfully'
    });
  } catch (error) {
    logger.error('Error generating report', error);
    res.status(500).json({ error: 'Failed to generate report', details: error.message });
  }
});

// ============================================
// ERROR HANDLING & SERVER STARTUP
// ============================================

// 404 handler
app.use((req, res) => {
  logger.warn('Route not found', { method: req.method, path: req.path });
  res.status(404).json({ error: 'Route not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled error', err);
  slos.metrics.errorBudgetUsed += 0.01;
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

const PORT = process.env.PORT || 4000;
const NODE_ENV = process.env.NODE_ENV || 'development';

async function startServer() {
  await initDB();
  
  const server = app.listen(PORT, () => {
    logger.info(`Server started successfully`, {
      port: PORT,
      environment: NODE_ENV,
      dataStore: 'in-memory (localStorage mode)',
      timestamp: new Date().toISOString()
    });
  });

  // Graceful shutdown
  const gracefulShutdown = async (signal) => {
    logger.info(`${signal} received, shutting down gracefully...`);
    
    server.close(async () => {
      logger.info('HTTP server closed');
      process.exit(0);
    });

    // Force shutdown after 30 seconds
    setTimeout(() => {
      logger.error('Forced shutdown after timeout');
      process.exit(1);
    }, 30000);
  };

  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));

  // Handle uncaught exceptions
  process.on('uncaughtException', (error) => {
    logger.error('Uncaught exception', error);
    process.exit(1);
  });

  process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled rejection', new Error(`Promise rejection: ${reason}`));
  });
}

startServer().catch(err => {
  logger.error('Failed to start server', err);
  process.exit(1);
});
