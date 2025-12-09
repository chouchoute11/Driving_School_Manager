# Phase 5: Release & Deployment Guide

**Status:** ✅ Complete  
**Version:** 1.0.0  
**Last Updated:** December 9, 2024

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Versioning Strategy](#versioning-strategy)
3. [Release Workflow](#release-workflow)
4. [Docker Image Registry](#docker-image-registry)
5. [Automated Release Pipeline](#automated-release-pipeline)
6. [Creating a Release](#creating-a-release)
7. [Docker Hub Setup](#docker-hub-setup)
8. [Release Artifacts](#release-artifacts)
9. [Verification](#verification)
10. [Troubleshooting](#troubleshooting)

---

## Overview

Phase 5 implements a complete release management system with:

✅ **Semantic Versioning** - MAJOR.MINOR.PATCH versioning  
✅ **Automated Git Tagging** - Tag-driven release process  
✅ **Multi-Registry Support** - GHCR + Docker Hub  
✅ **GitHub Releases** - Automated release notes with changelog  
✅ **Docker Image Artifacts** - Versioned and tagged images  
✅ **Slack Notifications** - Release announcements  
✅ **Local Release Script** - Easy version management  

---

## Versioning Strategy

### Semantic Versioning (SemVer)

This project follows [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH
  │      │      └─── Bug fixes, backwards compatible
  │      └────────── New features, backwards compatible
  └───────────────── Breaking changes, incompatible API
```

**Examples:**
- `1.0.0` → `1.0.1`: Bug fix release
- `1.0.1` → `1.1.0`: New feature release
- `1.1.0` → `2.0.0`: Breaking change release

### Version Management

Versions are stored in:
- `package.json` - Node.js version
- Git tags - Release markers
- Docker image tags - Container versions

---

## Release Workflow

```
┌─────────────────────────────────────────────┐
│         Developer Workflow                  │
├─────────────────────────────────────────────┤
│ 1. Make commits and push to main            │
│ 2. Run local tests and validation           │
│ 3. Execute release script                   │
│ 4. Script updates package.json              │
│ 5. Script creates Git tag                   │
│ 6. Script pushes tag to remote              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│   GitHub Actions Release Pipeline           │
├─────────────────────────────────────────────┤
│ 1. Validate version format                  │
│ 2. Run full test suite                      │
│ 3. Build Docker image                       │
│ 4. Push to GHCR (GitHub Container Registry) │
│ 5. Push to Docker Hub (optional)            │
│ 6. Create GitHub Release                    │
│ 7. Generate changelog                       │
│ 8. Send Slack notification                  │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│    Release Complete & Published             │
├─────────────────────────────────────────────┤
│ ✅ Docker images available                  │
│ ✅ GitHub Release created                   │
│ ✅ Changelog updated                        │
│ ✅ Slack notified                           │
│ ✅ Team alerted                             │
└─────────────────────────────────────────────┘
```

---

## Docker Image Registry

### GitHub Container Registry (GHCR)

**Primary registry for this project**

Available to:
- Public repositories: free
- Private repositories: free with GitHub Free plan

**Image location:**
```
ghcr.io/chouchoute11/Driving_School_Manager:1.0.0
ghcr.io/chouchoute11/Driving_School_Manager:latest
ghcr.io/chouchoute11/Driving_School_Manager:1.0
ghcr.io/chouchoute11/Driving_School_Manager:1
```

### Docker Hub (Optional)

**For wider distribution**

Requires:
- Docker Hub account
- `DOCKERHUB_USERNAME` secret in GitHub
- `DOCKERHUB_TOKEN` secret in GitHub

**Image location (if configured):**
```
docker.io/yourusername/driving-lesson-manager:1.0.0
docker.io/yourusername/driving-lesson-manager:latest
```

---

## Automated Release Pipeline

### Trigger Events

The release pipeline (`release.yml`) is triggered by:

**1. Git Tag Push**
```bash
git tag v1.0.0
git push origin v1.0.0
```

Automatically triggers when tag matches pattern: `v[0-9]+.[0-9]+.[0-9]+`

**2. Manual Workflow Dispatch**
- GitHub UI: Actions → Release & Publish → Run workflow
- Input: Version number (e.g., 1.0.0)
- Option: Mark as pre-release

### Pipeline Jobs

| Job | Purpose | Status |
|-----|---------|--------|
| `validate` | Check version format, prerequisites | ✅ |
| `test` | Run full test suite, lint checks | ✅ |
| `build-docker` | Build and push Docker images | ✅ |
| `release` | Create GitHub Release with changelog | ✅ |
| `notify-slack-release` | Send Slack notification | ✅ |
| `summary` | Generate pipeline summary | ✅ |

### Pipeline Outputs

Each release produces:

1. **Docker Images**
   - Semantic version tag (e.g., `1.0.0`)
   - Major version tag (e.g., `1`)
   - Minor version tag (e.g., `1.0`)
   - `latest` tag
   - Commit SHA tag

2. **GitHub Release**
   - Release notes with changelog
   - Direct links to Docker images
   - Commit information
   - Quick start instructions

3. **Notifications**
   - Slack message with release info
   - Links to release page
   - Docker image URLs
   - Deployment instructions

---

## Creating a Release

### Option 1: Using Release Script (Recommended)

**Prerequisites:**
- Working directory clean (no uncommitted changes)
- Sufficient permissions to push to main branch
- Tests should pass

**Steps:**

```bash
# 1. Ensure you're on main branch
git checkout main
git pull origin main

# 2. Run release script
./scripts/release.sh patch    # For bug fixes
./scripts/release.sh minor    # For new features
./scripts/release.sh major    # For breaking changes

# 3. Script will:
#    - Run tests
#    - Update package.json
#    - Update CHANGELOG.md
#    - Create Git commit
#    - Create Git tag
#    - Push to remote
#    - Trigger GitHub Actions

# 4. Monitor release at GitHub Actions
```

**Example Output:**
```
================================
Release Information
================================
Release Type: patch
Current Version: 1.0.0
New Version: 1.0.1
Tag: v1.0.1

Proceed with release 1.0.1? (y/n) y

... test execution ...
... git operations ...

================================
Release Complete! 🎉
================================

Version: 1.0.1
Tag: v1.0.1

Monitor the release at:
https://github.com/chouchoute11/Driving_School_Manager/actions
```

### Option 2: Manual Git Tagging

If the script isn't available:

```bash
# 1. Update version in package.json manually
vim package.json  # Change version to 1.0.1

# 2. Commit the change
git add package.json
git commit -m "chore: bump version to 1.0.1"

# 3. Create tag
git tag -a v1.0.1 -m "Release 1.0.1"

# 4. Push to remote
git push origin main
git push origin v1.0.1

# GitHub Actions will automatically start the release pipeline
```

### Option 3: GitHub UI Workflow Dispatch

```
1. Go to GitHub repository
2. Click "Actions" tab
3. Click "Release & Publish" workflow
4. Click "Run workflow"
5. Enter version: 1.0.1
6. Select pre-release: No
7. Click "Run workflow"
```

---

## Docker Hub Setup (Optional)

If you want to push images to Docker Hub:

### Step 1: Create Docker Hub Account

1. Go to [hub.docker.com](https://hub.docker.com)
2. Click "Sign up"
3. Create account with username

### Step 2: Create Access Token

1. Log in to Docker Hub
2. Click profile → Account Settings
3. Click "Security" → "Personal access tokens"
4. Click "Generate new token"
5. Name: `GitHub Actions Release`
6. Permissions: `Read & Write`
7. Generate and copy token

### Step 3: Add GitHub Secrets

1. Go to GitHub repository → Settings
2. Click "Secrets and variables" → "Actions"
3. Click "New repository secret"

**Add two secrets:**

| Name | Value |
|------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Your access token from Step 2 |

### Step 4: Images Available

After next release, images will be pushed to:

```bash
# Pull from Docker Hub
docker pull yourusername/driving-lesson-manager:1.0.0
docker pull yourusername/driving-lesson-manager:latest
```

---

## Release Artifacts

### Docker Images

Each release produces multiple tagged images:

**GHCR (Always Available)**
```
ghcr.io/chouchoute11/Driving_School_Manager:1.0.0        # Exact version
ghcr.io/chouchoute11/Driving_School_Manager:1.0          # Minor version
ghcr.io/chouchoute11/Driving_School_Manager:1            # Major version
ghcr.io/chouchoute11/Driving_School_Manager:latest       # Latest release
ghcr.io/chouchoute11/Driving_School_Manager:abc123...    # Commit SHA
```

**Docker Hub (If Configured)**
```
yourusername/driving-lesson-manager:1.0.0
yourusername/driving-lesson-manager:latest
```

### GitHub Release

Contains:
- Release notes with changelog
- Commit history since last release
- Quick start instructions
- Docker image pull commands
- Direct links to logs

**Location:** https://github.com/chouchoute11/Driving_School_Manager/releases

### Metadata & Labels

Docker images include metadata:

```bash
docker inspect ghcr.io/chouchoute11/Driving_School_Manager:1.0.0

# Labels include:
# - Version: 1.0.0
# - Build date: 2024-12-09T10:30:00Z
# - VCS reference: git commit SHA
# - Source: GitHub repository
```

---

## Verification

### Verify Release Created

```bash
# List local tags
git tag

# List remote tags
git ls-remote --tags origin

# View release on GitHub
https://github.com/chouchoute11/Driving_School_Manager/releases/v1.0.0
```

### Verify Docker Image

```bash
# Check GHCR
docker pull ghcr.io/chouchoute11/Driving_School_Manager:1.0.0
docker inspect ghcr.io/chouchoute11/Driving_School_Manager:1.0.0

# Check Docker Hub (if configured)
docker pull yourusername/driving-lesson-manager:1.0.0
docker run -p 4000:4000 yourusername/driving-lesson-manager:1.0.0
```

### Verify Slack Notification

- Check your Slack channel for release announcement
- Should include version, links, and deployment info

### Run Container

```bash
# Pull latest image
docker pull ghcr.io/chouchoute11/Driving_School_Manager:latest

# Run container
docker run -p 4000:4000 \
  ghcr.io/chouchoute11/Driving_School_Manager:latest

# Test health endpoint
curl http://localhost:4000/health

# Access application
open http://localhost:4000
```

---

## Troubleshooting

### Release Script Not Found

```bash
# Make script executable
chmod +x scripts/release.sh

# Ensure you're in project root
cd /path/to/Driving_lesson_manager/Driving_lesson_manager
```

### Git Tag Already Exists

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin :refs/tags/v1.0.0

# Create new tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### Docker Image Not Pushing

Check GitHub Actions logs:
1. Go to Actions tab
2. Click on failed "Release & Publish" workflow
3. Click on "Build Docker Image" job
4. Check logs for errors

**Common issues:**
- `GITHUB_TOKEN` not properly scoped
- Insufficient permissions on repository
- Docker registry authentication failed

### Slack Notification Not Sent

1. Verify `SLACK_SECRET` is set in GitHub Secrets
2. Check webhook URL is valid
3. Check Slack channel has webhook app installed
4. Review GitHub Actions logs for curl errors

### Version Not Updated in package.json

```bash
# Verify release script executed correctly
cat package.json | grep version

# If not updated, manually update:
vim package.json
git add package.json
git commit --amend --no-edit
git push origin main --force-with-lease
```

---

## Best Practices

### Release Checklist

- [ ] All tests passing locally
- [ ] No uncommitted changes
- [ ] Updated CHANGELOG.md (optional, script does this)
- [ ] Review recent commits in changelog
- [ ] Chose correct version bump (major/minor/patch)
- [ ] Slack webhook configured (if using notifications)
- [ ] Docker Hub secrets set (if pushing to Docker Hub)
- [ ] Test released Docker image before announcing

### Version Naming

**DO:**
- Use semantic versioning: 1.0.0, 1.1.0, 2.0.0
- Tag with `v` prefix: v1.0.0
- Use exact versions in production: don't use `latest`

**DON'T:**
- Use invalid formats: 1.0, v1, release-1
- Jump versions unnecessarily: go 1.0.0 → 1.0.1, not 1.0.0 → 1.2.0
- Mix versioning schemes

### Commit Messages

Good release commit:
```
chore: bump version to 1.0.1

- Bug fix release
- Includes hotfix for data validation
- All tests passing
```

### Release Frequency

- **Patch releases:** As needed for bugs (1-2 per month typical)
- **Minor releases:** Every sprint/month with new features
- **Major releases:** Annually or when breaking changes needed

---

## Summary

**Phase 5 provides:**

✅ Semantic versioning with SemVer compliance  
✅ Automated release workflow triggered by Git tags  
✅ Docker image building and multi-registry support  
✅ GitHub Release creation with auto-generated changelog  
✅ Slack notifications for release announcements  
✅ Local release script for easy version management  
✅ Complete release documentation and best practices  

**To create a release:**
```bash
./scripts/release.sh patch  # or minor/major
```

**That's it!** The rest is automated. 🚀

---

## Additional Resources

- [Semantic Versioning](https://semver.org)
- [Keep a Changelog](https://keepachangelog.com)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)
- [Docker Image Tagging](https://docs.docker.com/engine/reference/commandline/tag/)
- [GitHub Actions on Tag Push](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#push)
