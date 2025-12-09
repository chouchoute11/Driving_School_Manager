# 🚀 Release Quick Start Guide

## Create Your First Release in 2 Minutes

### Prerequisites
- ✅ Code committed and pushed to `main` branch
- ✅ All tests passing locally
- ✅ Clean working directory (`git status` shows nothing)

---

## Option 1: Automated Script (Recommended) ⭐

```bash
# 1. Navigate to project directory
cd /path/to/Driving_lesson_manager/Driving_lesson_manager

# 2. Run release script (choose one)
./scripts/release.sh patch    # Bug fix: 1.0.0 → 1.0.1
./scripts/release.sh minor    # New feature: 1.0.0 → 1.1.0
./scripts/release.sh major    # Breaking change: 1.0.0 → 2.0.0

# 3. Confirm when prompted
# Answer 'y' to confirm version bump

# 4. Watch the magic happen!
# - Version updated
# - Git commit created
# - Tag pushed
# - GitHub Actions starts
```

**That's it!** Everything else is automated. ✨

---

## What Happens Automatically

Once you push the tag, GitHub Actions automatically:

```
✅ Validates the version
✅ Runs all tests
✅ Builds Docker image
✅ Pushes to GitHub Container Registry
✅ Pushes to Docker Hub (if configured)
✅ Creates GitHub Release with changelog
✅ Sends Slack notification
✅ Completes in 5-10 minutes
```

---

## Verify Your Release

### Check GitHub Actions
```
Go to: https://github.com/chouchoute11/Driving_School_Manager/actions
Look for: Release & Publish workflow
Status: Should be green ✅
```

### Check GitHub Releases
```
Go to: https://github.com/chouchoute11/Driving_School_Manager/releases
See: New release with changelog and Docker commands
```

### Check Docker Registry
```bash
# List available versions
docker pull ghcr.io/chouchoute11/Driving_School_Manager:1.0.1
docker pull ghcr.io/chouchoute11/Driving_School_Manager:latest

# Run the released version
docker run -p 4000:4000 ghcr.io/chouchoute11/Driving_School_Manager:1.0.1
```

### Check Slack
```
Channel: #your-configured-channel
Message: "🚀 Release 1.0.1 Published"
Contains: Version, commit, links
```

---

## Example: Real Release

### Before Release
```
Version: 1.0.0
Latest Docker image: ghcr.io/.../Driving_School_Manager:1.0.0
Latest GitHub Release: v1.0.0
```

### Run Script
```bash
$ ./scripts/release.sh patch

================================
Release Information
================================
Release Type: patch
Current Version: 1.0.0
New Version: 1.0.1
Tag: v1.0.1

Proceed with release 1.0.1? (y/n) y

✅ Tests passed
✅ Updated package.json
✅ Updated CHANGELOG.md
✅ Created commit
✅ Created tag v1.0.1
✅ Pushed to remote

================================
Release Complete! 🎉
================================

Version: 1.0.1
Tag: v1.0.1
```

### After Release
```
Version: 1.0.1 ← Updated!
Latest Docker image: ghcr.io/.../Driving_School_Manager:1.0.1 ← New!
Latest GitHub Release: v1.0.1 ← New!
Latest tag: v1.0.1 ← New!
Slack message: "🚀 Release 1.0.1 Published" ← New!
```

---

## When to Use Each Release Type

### PATCH Release (1.0.0 → 1.0.1)
Use for:
- Bug fixes
- Security patches
- Minor improvements
- Hotfixes
- Documentation updates

Example:
```bash
./scripts/release.sh patch
# Results in: v1.0.1, v1.0.2, etc.
```

### MINOR Release (1.0.0 → 1.1.0)
Use for:
- New features
- Backwards-compatible additions
- New endpoints
- New capabilities

Example:
```bash
./scripts/release.sh minor
# Results in: v1.1.0, v1.2.0, etc.
```

### MAJOR Release (1.0.0 → 2.0.0)
Use for:
- Breaking changes
- API changes
- Major restructuring
- Incompatible changes

Example:
```bash
./scripts/release.sh major
# Results in: v2.0.0, v3.0.0, etc.
```

---

## Troubleshooting

### "Script not found" Error
```bash
chmod +x scripts/release.sh
./scripts/release.sh patch
```

### "Uncommitted changes" Error
```bash
git status              # See what needs committing
git add .              # Stage changes
git commit -m "your message"
./scripts/release.sh patch
```

### "Tag already exists" Error
```bash
# The tag v1.0.1 is already used. Either:

# 1. Use a different version
./scripts/release.sh minor  # Jump to v1.1.0 instead

# 2. Or delete the old tag and retry
git tag -d v1.0.1
git push origin :refs/tags/v1.0.1
./scripts/release.sh patch
```

### "Tests failed" Error
```bash
# Fix the failing tests first
npm run test:ci  # See which tests fail
# ... fix issues ...
git add .
git commit -m "fix: failing tests"
./scripts/release.sh patch
```

---

## Docker Hub Setup (Optional)

If you want images pushed to Docker Hub too:

### Step 1: Create Access Token
1. Go to hub.docker.com
2. Profile → Account Settings → Security
3. Personal access tokens → Generate
4. Copy the token

### Step 2: Add GitHub Secrets
1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Add `DOCKERHUB_USERNAME` = your username
3. Add `DOCKERHUB_TOKEN` = your token

### Step 3: Next Release
```bash
./scripts/release.sh patch

# Images will now be pushed to both:
# - ghcr.io/chouchoute11/Driving_School_Manager:1.0.1
# - docker.io/yourusername/driving-lesson-manager:1.0.1
```

---

## Release Checklist

Before running the release script:

- [ ] Working directory is clean (`git status`)
- [ ] All changes committed and pushed
- [ ] Tests passing locally (`npm run test:ci`)
- [ ] Code quality good (`npm run lint`)
- [ ] Changelog should be updated (script does this)
- [ ] Right version bump chosen (patch/minor/major)

After release:

- [ ] GitHub Actions workflow running
- [ ] All jobs showing green ✅
- [ ] Docker images in registry
- [ ] GitHub Release created
- [ ] Slack notification received (if configured)

---

## Common Release Commands

```bash
# Check current version
grep version package.json

# See version history
git tag | head -10

# See last 5 commits
git log --oneline -5

# See release script options
./scripts/release.sh

# View release script
cat scripts/release.sh

# Test without releasing
npm run test:ci
```

---

## Semantic Versioning Reference

```
Given a version number MAJOR.MINOR.PATCH:

MAJOR version when you make incompatible API changes
  Example: 1.0.0 → 2.0.0

MINOR version when you add functionality in a backwards compatible manner
  Example: 1.0.0 → 1.1.0

PATCH version when you make backwards compatible bug fixes
  Example: 1.0.0 → 1.0.1

Additional labels for pre-release and build metadata are available
as extensions to the MAJOR.MINOR.PATCH format.
```

Source: https://semver.org

---

## Need More Help?

### Quick Links
- 📖 Full Guide: `PHASE5_RELEASE.md` (600+ pages)
- 📝 Changelog: `CHANGELOG.md` (version history)
- 🔧 Script: `scripts/release.sh` (source code)
- ⚙️ Workflow: `.github/workflows/release.yml` (automation)

### Common Questions

**Q: Can I undo a release?**
A: You'll need to delete the Git tag:
```bash
git tag -d v1.0.1
git push origin :refs/tags/v1.0.1
```

**Q: Where are the Docker images?**
A: In the GitHub Container Registry (GHCR)
```bash
docker pull ghcr.io/chouchoute11/Driving_School_Manager:1.0.1
```

**Q: Why should I use releases?**
A: Releases provide:
- Version tracking
- Docker artifacts
- Release notes
- Commit history
- Team notifications
- Production references

**Q: How often should I release?**
A: Depends on your workflow:
- Patch: As needed (1-2/month for bugs)
- Minor: Every sprint (1/month with new features)
- Major: Annually or when breaking changes needed

---

## 🎉 You're Ready!

Everything is set up and automated. Just run:

```bash
./scripts/release.sh patch
```

And watch GitHub Actions do the rest! 🚀

---

**Questions or issues?** Check `PHASE5_RELEASE.md` for the comprehensive guide.

Happy releasing! 🎊
