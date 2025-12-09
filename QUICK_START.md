# Quick Start Guide - Driving School Lesson Manager

## 🚀 5-Minute Setup

### Prerequisites
- Node.js 18+ 
- Docker & Docker Compose
- Git

### Development Setup

# 1. Clone & Install
git clone <repository>
cd Driving_lesson_manager
npm install

# 2. Start Application
docker-compose up

# 3. Access Dashboard
open http://localhost:3000


### Health Checks

# Liveness probe
curl http://localhost:3000/health

# Readiness probe
curl http://localhost:3000/ready

# Response should include:
{
  "status": "healthy",
  "database": "connected",
  "slos": { ... }
}


---

## 📋 Common Commands

### Development

npm start              # Run server
npm run dev            # Run with auto-reload
npm test              # Run tests
npm run lint          # Check code quality
npm run lint:fix      # Fix linting issues
npm run format        # Format code with Prettier


### Docker

docker-compose up     # Start all services
docker-compose down   # Stop all services
docker-compose logs   # View logs
docker build -t app . # Build image manually


### Git Workflow

# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "feat(api): add new endpoint"

# Push and create PR
git push origin feature/new-feature

# After merge, clean up
git branch -d feature/new-feature


---

## 🔧 Configuration

### Environment Variables

# .env file
PORT=3000
NODE_ENV=development

DB_HOST=localhost
DB_USER=root
DB_PASSWORD=password
DB_NAME=driving_school_db


### API Endpoints Reference

#### Lessons

# List lessons
curl GET http://localhost:3000/api/lessons

# Create lesson
curl -X POST http://localhost:3000/api/lessons \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": 1,
    "instructor_id": 1,
    "lesson_date": "2024-12-15T10:00:00",
    "duration": 60,
    "notes": "Focus on parking"
  }'

# Update lesson
curl -X PUT http://localhost:3000/api/lessons/1 \
  -H "Content-Type: application/json" \
  -d '{"status": "completed"}'

# Delete lesson
curl -X DELETE http://localhost:3000/api/lessons/1


#### Students

# List students
curl GET http://localhost:3000/api/students

# Register student
curl -X POST http://localhost:3000/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "555-1234",
    "license_class": "B"
  }'


#### Instructors

# List instructors
curl GET http://localhost:3000/api/instructors

# Register instructor
curl -X POST http://localhost:3000/api/instructors \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Jane",
    "last_name": "Smith",
    "email": "jane@example.com",
    "license_number": "DL123456"
  }'


#### Reports

# List reports
curl GET http://localhost:3000/api/reports

# Generate report
curl -X POST http://localhost:3000/api/reports \
  -H "Content-Type: application/json" \
  -d '{
    "type": "attendance",
    "student_id": 1,
    "period_start": "2024-12-01",
    "period_end": "2024-12-31"
  }'


---

## 🧪 Testing

### Run Tests

# All tests
npm test

# Specific test file
npm test -- index.test.js

# Watch mode
npm test -- --watch

# Coverage report
npm run test:coverage


### Test Structure
javascript
describe('API Endpoint', () => {
  test('should create resource', async () => {
    const response = await apiCall('/api/endpoint', 'POST', data);
    expect(response.status).toBe(201);
  });
});


---

## 🔍 Debugging

### View Logs

# Docker container logs
docker-compose logs -f app

# Filter by level
docker-compose logs app | grep "ERROR"

# Last N lines
docker-compose logs --tail=100 app


### Structured Log Query

# Find errors
grep '"level":"ERROR"' logs.json | jq '.'

# Count requests by method
jq '.method' logs.json | sort | uniq -c


---

## 📊 Monitoring & SLOs

### SLO Dashboard

GET /health returns:
{
  "slos": {
    "errorRate": "0.0080",
    "errorBudgetRemaining": "0.0092",
    "targetUptime": "99%",
    "targetLatency": "200ms"
  }
}


### Key Metrics
- **Error Rate**: Target < 1%
- **Uptime**: Target 99%
- **Response Time**: p95 < 200ms
- **Error Budget**: 1% per month

---

## 🚨 Troubleshooting

### Database Connection Failed

# Check MySQL service
docker ps | grep mysql

# Restart services
docker-compose restart

# Check logs
docker-compose logs mysql


### Port Already in Use

# Check what's using port 3000
lsof -i :3000

# Kill process or use different port
PORT=3001 docker-compose up


### Tests Failing

# Clear Jest cache
npm test -- --clearCache

# Run with verbose output
npm test -- --verbose

# Run specific test
npm test -- --testNamePattern="should create"


### Linting Errors

# Check all issues
npm run lint

# Auto-fix most issues
npm run lint:fix

# Format code
npm run format


---

## 📚 Documentation Links

- **Full DevOps Guide**: See `DEVOPS_ROADMAP.md`
- **Implementation Details**: See `IMPLEMENTATION_SUMMARY.md`
- **Original README**: See `README.md`

---

## 🔐 Security Checklist

Before committing:
- [ ] No `.env` files committed
- [ ] No API keys in code
- [ ] Secrets in environment variables only
- [ ] Linting passes: `npm run lint`
- [ ] No console.log() in production code
- [ ] Tests pass: `npm test`

Before pushing:
- [ ] Commit messages follow convention
- [ ] Branch name follows pattern
- [ ] No large sensitive files
- [ ] All changes documented

---

## 💡 Pro Tips

1. **Use Git aliases** for common commands
   
   git config --global alias.co checkout
   git config --global alias.br branch
   

2. **Enable Git hooks** for automatic checks
   
   npm install husky --save-dev
   npx husky install
   

3. **Use VS Code extensions**
   - ESLint
   - Prettier
   - Docker
   - GitLens

4. **Monitor in real-time**
   
   docker-compose logs -f --tail=50 app
   

---

## ❓ FAQ

**Q: How do I create a new feature?**
A: `git checkout -b feature/my-feature` → make changes → `git commit -m "feat: ..."` → push → create PR

**Q: How do I fix linting errors?**
A: Run `npm run lint:fix` to auto-fix most issues, then review and commit.

**Q: Can I use a different database?**
A: Update `dbConfig` in `index.js` and the Docker Compose MySQL service in `docker-compose.yml`.

**Q: How do I scale to Kubernetes?**
A: Use the Dockerfile and create Kubernetes manifests. See Phase 4 enhancements in DEVOPS_ROADMAP.md.

**Q: Where are the logs?**
A: Check console output or use `docker-compose logs app` for structured JSON logs.

---

## 🆘 Getting Help

1. Check the DEVOPS_ROADMAP.md documentation
2. Review GitHub Actions CI/CD logs for build issues
3. Check Docker container logs: `docker-compose logs`
4. Open an issue on GitHub with details
5. Review commit history for similar changes: `git log --grep="keyword"`

---

**Last Updated:** December 8, 2024  
**Version:** 1.0  
**Status:** ✅ Ready for Development
