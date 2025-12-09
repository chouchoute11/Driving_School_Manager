# Slack Notifications Setup Guide

## 📋 Overview

This guide walks you through setting up GitHub Actions to send Slack notifications for CI/CD pipeline results.

---

## Step 1: Create a Slack Incoming Webhook

### 1.1 Go to Slack App Directory

1. Open your Slack workspace
2. Click on **Workspace Settings** (bottom left, workspace name)
3. Select **Apps and integrations**
4. Click **Build** (top right)

### 1.2 Create New App

1. Click **Create New App**
2. Select **From scratch**
3. Enter app name: `GitHub CI Notifications`
4. Select your workspace
5. Click **Create App**

### 1.3 Enable Incoming Webhooks

1. Go to **Incoming Webhooks** (left sidebar)
2. Toggle **Activate Incoming Webhooks** to ON
3. Click **Add New Webhook to Workspace**
4. Select the channel where you want notifications (e.g., #devops or #builds)
5. Click **Allow**

### 1.4 Copy Webhook URL

1. You'll see a new webhook URL like:
   ```
   https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
   ```
2. **Copy this URL** - you'll need it for GitHub

---

## Step 2: Add Webhook to GitHub Secrets

### 2.1 Go to GitHub Repository Settings

1. Open your GitHub repository
2. Click **Settings** (top right)
3. Click **Secrets and variables** → **Actions** (left sidebar)

### 2.2 Create New Secret

1. Click **New repository secret**
2. **Name**: `SLACK_SECRET` (exactly as shown - this is required!)
3. **Value**: Paste the webhook URL you copied from Slack
4. Click **Add secret**

✅ Your secret is now secure and ready to use!

---

## Step 3: Verify CI Pipeline Notifications

The CI pipelines are configured to send Slack notifications:

1. **`.github/workflows/ci.yml`** - Main CI pipeline
2. **`.github/workflows/ci-phase4.yml`** - Phase 4 pipeline (with extended tests)

Both use the `SLACK_SECRET` to send notifications.

### What You'll See in Slack

When a CI pipeline runs, you'll receive a message like:

#### ✅ Success
```
✅ CI/CD Pipeline - success
Build success for chouchoute11/Driving_School_Manager

Repository: chouchoute11/Driving_School_Manager
Branch: main
Lint: success
Unit Tests: success
Integration Tests: success
Build: success
Security: success
Commit: abc1234...
Author: chouchoute11
Message: feat: add new feature
```

#### ❌ Failure
```
❌ CI/CD Pipeline - failure
Build failure for chouchoute11/Driving_School_Manager

Repository: chouchoute11/Driving_School_Manager
Branch: main
Lint: failure
Unit Tests: success
Integration Tests: success
Build: success
Security: success
Commit: def5678...
Author: chouchoute11
Message: fix: bug fix
```

### Notification Details

The Slack message includes:
- **Status Emoji**: ✅ (success) or ❌ (failure) with green/red color
- **Pipeline Status**: Build status (success/failure)
- **All Job Results**: Lint, Unit Tests, Integration Tests, Build, Security
- **Commit Info**: SHA (clickable link) and author
- **Repository & Branch**: Full context with links
- **Commit Message**: The message for that commit

---

## Step 4: Test Slack Notifications

### 4.1 Trigger a Test Pipeline Run

Make a small change and push to GitHub:

```bash
# Make a small change
echo "# Test" >> TEST.md

# Commit and push
git add TEST.md
git commit -m "test: trigger ci pipeline"
git push origin main
```

### 4.2 Wait for Notification

1. Go to GitHub Actions tab
2. Watch the workflow run
3. Check your Slack channel for the notification message

✅ If you see the message, Slack integration is working!

---

## Advanced Configuration

### Custom Slack Channel per Branch

You can send notifications to different channels based on branch:

```yaml
- name: Send Slack notification (main)
  if: github.ref == 'refs/heads/main'
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_MAIN }}

- name: Send Slack notification (develop)
  if: github.ref == 'refs/heads/develop'
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_DEVELOP }}
```

### Slack Message Formatting

The current notification uses this format:

```json
{
  "attachments": [
    {
      "color": "good|danger",
      "title": "✅|❌ CI/CD Pipeline - success|failure",
      "fields": [
        {
          "title": "Repository",
          "value": "chouchoute11/Driving_School_Manager"
        },
        {
          "title": "Job Results",
          "value": "Lint, Unit Tests, Build, Security"
        }
      ]
    }
  ]
}
```

---

## Troubleshooting

### 1. No Slack Messages Appearing

**Problem**: You don't see notifications in Slack

**Solutions**:
- ✅ Verify the webhook URL is correct in GitHub Secrets
- ✅ Check the Slack channel name is correct
- ✅ Ensure the GitHub app has permission to post in that channel
- ✅ Check GitHub Actions logs for errors

### 2. Webhook URL Shows as Invalid

**Problem**: GitHub shows "Invalid webhook URL"

**Solutions**:
- ✅ Copy the full URL including `https://`
- ✅ Make sure there are no extra spaces
- ✅ Regenerate the webhook URL in Slack

### 3. Messages Are Going to Wrong Channel

**Problem**: Notifications appear in wrong Slack channel

**Solutions**:
- ✅ Go back to Slack webhook settings
- ✅ Delete the old webhook
- ✅ Create a new webhook pointing to the correct channel
- ✅ Update the URL in GitHub Secrets

### 4. Webhook URL Expired

**Problem**: Slack messages stopped working after some time

**Solutions**:
- ✅ Slack webhooks don't expire, but the integration might be disabled
- ✅ Check Slack workspace settings
- ✅ Verify the app is still active in your workspace
- ✅ Regenerate a new webhook if needed

---

## Slack Notification Examples

### ✅ Success Notification

```
✅ CI/CD Pipeline - success

Repository: your-org/your-repo
Branch: main
Lint: success
Unit Tests: success
Integration Tests: success
Build: success
Security: success

Commit: 3c6d7e9a2f1b4c5d
Author: john-doe
```

### ❌ Failure Notification

```
❌ CI/CD Pipeline - failure

Repository: your-org/your-repo
Branch: develop
Lint: failure
Unit Tests: failure
Integration Tests: success
Build: success
Security: success

Commit: 2a8f3b5c7d9e1a6c
Author: jane-smith
```

---

## More Advanced Features

### Mention Users on Failure

Add this to `.github/workflows/ci-phase4.yml`:

```yaml
- name: Notify failure to Slack with mention
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "<!here> Build failed on ${{ github.ref_name }}"
      }
```

### Add Thread Replies

```yaml
- name: Send thread reply
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "thread_ts": "${{ env.SLACK_THREAD_TS }}",
        "text": "Build status update: ..."
      }
```

---

## GitHub Actions Integration Files

### Current Workflow: `.github/workflows/ci-phase4.yml`

The workflow already has Slack integration in the `notify` job:

```yaml
notify:
  runs-on: ubuntu-latest
  name: Send Notifications
  needs: [ lint, unit-tests, integration-tests, all-tests, build, security ]
  if: always()
  
  steps:
    - name: Send Slack notification
      if: env.SLACK_WEBHOOK != ''
      uses: slackapi/slack-github-action@v1
      with:
        webhook-url: ${{ secrets.SLACK_WEBHOOK }}
        payload: |
          {
            "attachments": [...]
          }
```

---

## Quick Reference

| Step | Action |
|------|--------|
| 1 | Create Slack webhook in workspace |
| 2 | Copy webhook URL |
| 3 | Add to GitHub Secrets as `SLACK_WEBHOOK` |
| 4 | Push code to trigger pipeline |
| 5 | Check Slack for notification message |

---

## Support

If you have issues:

1. **Check GitHub Actions logs**: Settings → Actions → All workflows → Select workflow → See logs
2. **Verify webhook URL**: Go to Slack workspace settings → Apps → GitHub app → Webhook settings
3. **Test webhook manually**:
   ```bash
   curl -X POST -H 'Content-type: application/json' \
     --data '{"text":"Test message"}' \
     YOUR_WEBHOOK_URL
   ```

---

## Security Notes

- 🔒 **Never commit webhook URLs** to repository
- 🔒 **Always use GitHub Secrets** for sensitive URLs
- 🔒 **Webhook URLs are unique** - don't share them publicly
- 🔒 **Regenerate webhooks** if you think they're compromised

---

## Next Steps

After setting up Slack notifications:

- ✅ Monitor builds in Slack channel
- ✅ Set up alerts for failures
- ✅ Configure custom messages per team
- ✅ Integrate with other tools (PagerDuty, JIRA, etc.)

