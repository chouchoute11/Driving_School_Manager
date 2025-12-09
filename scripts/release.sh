#!/bin/bash

##############################################################################
# Release Script - Automates versioning, tagging, and release creation
#
# Usage: ./scripts/release.sh <major|minor|patch> [--skip-tests]
#
# Examples:
#   ./scripts/release.sh major        # Release v2.0.0
#   ./scripts/release.sh minor        # Release v1.1.0
#   ./scripts/release.sh patch        # Release v1.0.1
#   ./scripts/release.sh patch --skip-tests  # Skip test execution
##############################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
  echo -e "${BLUE}================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}================================${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

# Validate inputs
if [ $# -lt 1 ]; then
  echo "Usage: $0 <major|minor|patch> [--skip-tests]"
  exit 1
fi

RELEASE_TYPE=$1
SKIP_TESTS=${2:-}

if [[ ! "$RELEASE_TYPE" =~ ^(major|minor|patch)$ ]]; then
  print_error "Invalid release type: $RELEASE_TYPE"
  echo "Valid options: major, minor, patch"
  exit 1
fi

# Check prerequisites
print_header "Checking Prerequisites"

if ! command -v jq &> /dev/null; then
  print_warning "jq not installed, skipping JSON validation"
fi

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  print_error "Not in a Git repository"
  exit 1
fi
print_success "Git repository found"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
  print_error "Uncommitted changes detected. Please commit or stash changes."
  exit 1
fi
print_success "Working directory clean"

# Get current version from package.json
CURRENT_VERSION=$(grep '"version"' package.json | head -1 | sed -E 's/.*"([0-9.]+)".*/\1/')
print_info "Current version: $CURRENT_VERSION"

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Calculate new version
case "$RELEASE_TYPE" in
  major)
    NEW_MAJOR=$((MAJOR + 1))
    NEW_MINOR=0
    NEW_PATCH=0
    ;;
  minor)
    NEW_MAJOR=$MAJOR
    NEW_MINOR=$((MINOR + 1))
    NEW_PATCH=0
    ;;
  patch)
    NEW_MAJOR=$MAJOR
    NEW_MINOR=$MINOR
    NEW_PATCH=$((PATCH + 1))
    ;;
esac

NEW_VERSION="$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
TAG="v$NEW_VERSION"

print_header "Release Information"
echo "Release Type: $RELEASE_TYPE"
echo "Current Version: $CURRENT_VERSION"
echo "New Version: $NEW_VERSION"
echo "Tag: $TAG"
echo ""

# Confirm release
read -p "Proceed with release $NEW_VERSION? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  print_warning "Release cancelled"
  exit 1
fi

# Run tests if not skipped
if [ "$SKIP_TESTS" != "--skip-tests" ]; then
  print_header "Running Tests"
  npm run test:ci || {
    print_error "Tests failed. Release cancelled."
    exit 1
  }
  print_success "All tests passed"
else
  print_warning "Tests skipped"
fi

# Update package.json version
print_header "Updating Version"
sed -i "s/\"version\": \"$CURRENT_VERSION\"/\"version\": \"$NEW_VERSION\"/" package.json
print_success "Updated package.json to version $NEW_VERSION"

# Update package-lock.json if it exists
if [ -f "package-lock.json" ]; then
  npm install --package-lock-only > /dev/null 2>&1
  print_success "Updated package-lock.json"
fi

# Create CHANGELOG entry (if CHANGELOG.md exists)
if [ -f "CHANGELOG.md" ]; then
  print_header "Updating CHANGELOG"
  
  # Get recent commits
  PREVIOUS_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [ -z "$PREVIOUS_TAG" ]; then
    COMMITS=$(git log --pretty=format:"- %h %s" | head -20)
  else
    COMMITS=$(git log $PREVIOUS_TAG..HEAD --pretty=format:"- %h %s")
  fi
  
  # Create new CHANGELOG entry
  RELEASE_DATE=$(date +"%Y-%m-%d")
  TEMP_FILE=$(mktemp)
  
  cat > "$TEMP_FILE" << EOF
# Changelog

All notable changes to this project will be documented in this file.

## [$NEW_VERSION] - $RELEASE_DATE

### Added
- Initial release

### Changed
- Documentation updates

### Fixed
- Bug fixes

### Security
- Security improvements

### Commits
$COMMITS

---

EOF
  
  # Append rest of CHANGELOG
  tail -n +2 CHANGELOG.md >> "$TEMP_FILE"
  mv "$TEMP_FILE" CHANGELOG.md
  
  print_success "Updated CHANGELOG.md"
else
  print_warning "CHANGELOG.md not found, skipping"
fi

# Commit version changes
print_header "Creating Git Commit"
git add package.json package-lock.json 2>/dev/null || git add package.json
if [ -f "CHANGELOG.md" ]; then
  git add CHANGELOG.md
fi

git commit -m "chore: bump version to $NEW_VERSION"
print_success "Created commit for version bump"

# Create Git tag
print_header "Creating Git Tag"
git tag -a "$TAG" -m "Release $NEW_VERSION

Version: $NEW_VERSION
Release Date: $(date)
Description: Release of version $NEW_VERSION

This tag triggers the release pipeline."

print_success "Created tag: $TAG"

# Push changes and tag
print_header "Pushing to Remote"
git push origin main || {
  print_warning "Failed to push to remote. Rolling back..."
  git reset --soft HEAD~1
  git tag -d "$TAG"
  print_error "Release cancelled and rolled back"
  exit 1
}
print_success "Pushed main branch"

git push origin "$TAG" || {
  print_warning "Failed to push tag. Rolling back..."
  git reset --soft HEAD~1
  git tag -d "$TAG"
  print_error "Release cancelled and rolled back"
  exit 1
}
print_success "Pushed tag: $TAG"

# Success summary
print_header "Release Complete! 🎉"
echo ""
echo "Version: $NEW_VERSION"
echo "Tag: $TAG"
echo ""
echo "What happens next:"
echo "1. GitHub Actions will automatically build and push Docker images"
echo "2. A GitHub Release will be created"
echo "3. Slack notification will be sent (if configured)"
echo ""
echo "Monitor the release at:"
echo "https://github.com/$GITHUB_REPOSITORY/actions"
echo ""
echo "View the release at:"
echo "https://github.com/$GITHUB_REPOSITORY/releases/tag/$TAG"
echo ""
