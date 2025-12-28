# Deploying to Google Cloud Run

This guide walks you through deploying the YourHealthFirstApp to Google Cloud Run using GitHub Actions.

## Prerequisites

Before deploying, ensure you have completed the following:

- [ ] GCP Project created and configured
- [ ] Run the `setup-gcp-cloudrun.sh` script (or `.cmd`/`.ps1` for Windows)
- [ ] GitHub Secrets configured (see [GitHub Secrets Setup](#github-secrets-setup))
- [ ] Dockerfiles in place for both Angular UI and Flask BO

---

## GitHub Secrets Setup

Add the following secrets to your GitHub repository:

1. Go to: **Repository → Settings → Secrets and variables → Actions**
2. Click **"New repository secret"** and add:

| Secret Name | Description |
|-------------|-------------|
| `GCP_PROJECT_ID` | Your GCP Project ID (e.g., `engineering-college-apps`) |
| `GCP_SERVICE_ACCOUNT_EMAIL` | Service account email from setup script |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity Provider from setup script |
| `GCP_SA_KEY` | *(Alternative)* Full JSON content of service account key |

---

## Deployment Order

> **Important:** Always deploy the backend API first, then the frontend UI.

### Why This Order?

1. **Backend First** - The Angular UI depends on the Flask API for data
2. **API Availability** - If the API isn't running, the UI may fail or show errors during initialization
3. **URL Configuration** - After deploying Flask, you'll get an API URL that may need to be configured in the Angular app

---

## Step 1: Deploy Flask Back Office (API)

The Flask Back Office provides the REST API endpoints for the application.

### 1.1 Navigate to GitHub Actions

Go to: [https://github.com/javakishore-veleti/YourHealthFirstApp/actions](https://github.com/javakishore-veleti/YourHealthFirstApp/actions)

### 1.2 Select the Deploy Workflow

1. In the left sidebar, click **"GCP Healthcare BO - Deploy"**
2. Click the **"Run workflow"** dropdown button (on the right side)

### 1.3 Configure Deployment Options

Select the following options:

| Option | Value | Description |
|--------|-------|-------------|
| **Environment** | `dev` | Target environment (dev/staging/prod) |
| **Region** | `us-central1` | GCP region for deployment |

### 1.4 Start Deployment

Click the green **"Run workflow"** button.

### 1.5 Monitor Progress

- The workflow will appear in the list with a yellow dot (in progress)
- Click on the workflow run to see detailed logs
- Wait for all steps to complete (green checkmark)

### 1.6 Get the API URL

After successful deployment, you'll find the **Service URL** in the workflow summary:

```
https://healthcare-plans-bo-dev-xxxxxxxxxx-uc.a.run.app
```

> **📝 Note:** Save this URL! You may need it to configure the Angular UI's API endpoint.

### 1.7 Verify the API

Test the API is running by visiting:

```
https://healthcare-plans-bo-dev-xxxxxxxxxx-uc.a.run.app/api/v1/health/
```

You should see a health check response.

---

## Step 2: Deploy Angular UI (Frontend)

The Angular UI provides the web interface for users.

### 2.1 Navigate to GitHub Actions

Go to: [https://github.com/javakishore-veleti/YourHealthFirstApp/actions](https://github.com/javakishore-veleti/YourHealthFirstApp/actions)

### 2.2 Select the Deploy Workflow

1. In the left sidebar, click **"GCP Healthcare UI - Deploy"**
2. Click the **"Run workflow"** dropdown button

### 2.3 Configure Deployment Options

Select the following options:

| Option | Value | Description |
|--------|-------|-------------|
| **Environment** | `dev` | Target environment (must match API environment) |
| **Region** | `us-central1` | GCP region (should match API region) |

### 2.4 Start Deployment

Click the green **"Run workflow"** button.

### 2.5 Monitor Progress

- Watch the workflow progress in the Actions tab
- Wait for all steps to complete successfully

### 2.6 Get the UI URL

After successful deployment, you'll find the **Service URL** in the workflow summary:

```
https://healthcare-plans-ui-dev-xxxxxxxxxx-uc.a.run.app
```

### 2.7 Verify the Application

Open the UI URL in your browser to verify the application is running correctly.

---

## Deployment Summary

After completing both deployments, you'll have:

| Service | URL Pattern | Purpose |
|---------|-------------|---------|
| **Flask API** | `https://healthcare-plans-bo-dev-xxx.a.run.app` | Backend REST API |
| **Angular UI** | `https://healthcare-plans-ui-dev-xxx.a.run.app` | Frontend Web Application |

---

## Other Workflow Actions

Besides deployment, you have additional workflows available:

| Workflow | Purpose |
|----------|---------|
| **Stop** | Scale service to 0 instances (pause without deleting) |
| **Restart** | Restart service with new instances |
| **Health Check** | Verify service health and get status |
| **Status** | View all deployed services and their status |
| **Destroy** | Permanently delete the service (⚠️ destructive) |

---

## Deploying to Different Environments

To deploy to staging or production:

1. Run the deploy workflow
2. Select the appropriate environment:
   - `dev` - Development/testing
   - `staging` - Pre-production testing
   - `prod` - Production

> **⚠️ Production Deployments:** Always test in `dev` and `staging` before deploying to `prod`.

---

## Troubleshooting

### Common Issues

**1. Workflow fails at authentication step**
- Verify GitHub Secrets are correctly configured
- Check that the service account has the required IAM roles

**2. Docker build fails**
- Ensure Dockerfile exists in the correct location
- Check that all required files (nginx.conf, requirements.txt) are present

**3. Service URL returns 404 or error**
- Check the workflow logs for deployment errors
- Verify the health check endpoint is working
- Review Cloud Run logs in GCP Console

### Viewing Logs

To view detailed logs:
1. Go to [GCP Cloud Run Console](https://console.cloud.google.com/run)
2. Select your service
3. Click on "Logs" tab

---

## Quick Reference

### Deploy Commands (via GitHub Actions UI)

```
1. Flask API:  Actions → "GCP Healthcare BO - Deploy" → Run workflow
2. Angular UI: Actions → "GCP Healthcare UI - Deploy" → Run workflow
```

### Useful Links

- **GitHub Actions:** [Repository Actions Tab](https://github.com/javakishore-veleti/YourHealthFirstApp/actions)
- **GCP Cloud Run Console:** [Cloud Run Dashboard](https://console.cloud.google.com/run)
- **GCP Artifact Registry:** [Container Images](https://console.cloud.google.com/artifacts)

---

## Next Steps After Deployment

1. **Configure API URL in Angular** - Update environment files if needed
2. **Set up Custom Domain** - Configure custom domain in Cloud Run settings
3. **Enable CI/CD** - Modify workflows to trigger on push to specific branches
4. **Set up Monitoring** - Configure Cloud Monitoring alerts
