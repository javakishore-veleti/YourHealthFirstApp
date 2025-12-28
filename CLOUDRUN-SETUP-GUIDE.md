# Cloud Run Deployment Setup Guide

This guide walks you through setting up Google Cloud Run deployment for the Healthcare Plans UI Angular application using GitHub Actions.

## Overview

The deployment process uses:
- **Google Cloud Run** - Serverless container platform
- **Google Artifact Registry** - Docker image storage
- **Workload Identity Federation** - Secure keyless authentication (recommended)
- **GitHub Actions** - CI/CD pipeline with manual trigger

---

## Prerequisites

1. **Google Cloud Account** with billing enabled
2. **GCP Project** created
3. **gcloud CLI** installed and authenticated
4. **GitHub repository** with admin access

---

## Step 1: GCP Setup

### Option A: Automated Setup (Recommended)

1. Download the `setup-gcp-cloudrun.sh` script
2. Edit the configuration variables at the top:
   ```bash
   PROJECT_ID="your-gcp-project-id"
   REGION="us-central1"
   GITHUB_REPO="javakishore-veleti/YourHealthFirstApp"
   ```
3. Run the script:
   ```bash
   chmod +x setup-gcp-cloudrun.sh
   ./setup-gcp-cloudrun.sh
   ```

### Option B: Manual Setup

#### 1.1 Enable Required APIs

```bash
gcloud config set project YOUR_PROJECT_ID

gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    iamcredentials.googleapis.com \
    iam.googleapis.com
```

#### 1.2 Create Service Account

```bash
# Create service account
gcloud iam service-accounts create github-actions-cloudrun \
    --display-name="GitHub Actions Cloud Run Deployer"

# Set variable for convenience
SA_EMAIL="github-actions-cloudrun@YOUR_PROJECT_ID.iam.gserviceaccount.com"

# Grant required roles
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.admin"
```

#### 1.3 Create Artifact Registry Repository

```bash
gcloud artifacts repositories create healthcare-plans-ui \
    --repository-format=docker \
    --location=us-central1 \
    --description="Docker images for Healthcare Plans UI"
```

#### 1.4 Setup Workload Identity Federation

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create github-actions-pool \
    --location="global" \
    --display-name="GitHub Actions Pool"

# Create OIDC Provider
gcloud iam workload-identity-pools providers create-oidc github-actions-provider \
    --location="global" \
    --workload-identity-pool="github-actions-pool" \
    --display-name="GitHub Actions Provider" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository=='javakishore-veleti/YourHealthFirstApp'"

# Get the provider resource name
gcloud iam workload-identity-pools providers describe github-actions-provider \
    --workload-identity-pool="github-actions-pool" \
    --location="global" \
    --format="value(name)"

# Allow GitHub to impersonate service account
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/javakishore-veleti/YourHealthFirstApp"
```

---

## Step 2: Configure GitHub Secrets

Navigate to your GitHub repository:
**Settings → Secrets and variables → Actions → New repository secret**

### Required Secrets (Workload Identity Federation)

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `GCP_PROJECT_ID` | Your GCP Project ID | `my-healthcare-project` |
| `GCP_SERVICE_ACCOUNT_EMAIL` | Service Account email | `github-actions-cloudrun@my-project.iam.gserviceaccount.com` |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full provider path | `projects/123456/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider` |

### Alternative: Service Account Key (Less Secure)

If you prefer using a service account key instead:

| Secret Name | Description |
|-------------|-------------|
| `GCP_SA_KEY` | Contents of the JSON key file |

To create a key:
```bash
gcloud iam service-accounts keys create key.json \
    --iam-account=github-actions-cloudrun@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

Then copy the entire contents of `key.json` into the `GCP_SA_KEY` secret.

---

## Step 3: Add Workflow to Repository

1. Create the directory structure if it doesn't exist:
   ```bash
   mkdir -p .github/workflows
   ```

2. Copy `deploy-healthcare-ui-cloudrun.yml` to `.github/workflows/`

3. Commit and push:
   ```bash
   git add .github/workflows/deploy-healthcare-ui-cloudrun.yml
   git commit -m "Add Cloud Run deployment workflow"
   git push
   ```

---

## Step 4: Run the Deployment

1. Go to your GitHub repository
2. Click on **Actions** tab
3. Select **"Deploy Healthcare Plans UI to Cloud Run"** workflow
4. Click **"Run workflow"**
5. Select:
   - **Environment**: `dev`, `staging`, or `prod`
   - **Region**: Your preferred GCP region
6. Click **"Run workflow"**

---

## Workflow Features

### Manual Trigger with Options
- Choose deployment environment (dev/staging/prod)
- Select GCP region
- Each environment gets a unique Cloud Run service

### Image Tagging
- Images tagged with commit SHA for traceability
- Also tagged as `latest` for convenience

### Cloud Run Configuration
- Port: 8080 (matches nginx config)
- Memory: 512Mi
- CPU: 1
- Min instances: 0 (scale to zero)
- Max instances: 10
- Public access enabled (`--allow-unauthenticated`)

---

## Troubleshooting

### Common Issues

**1. Permission Denied Errors**
```
Error: Permission 'run.services.create' denied
```
Solution: Ensure the service account has `roles/run.admin`

**2. Artifact Registry Push Failed**
```
Error: failed to push image
```
Solution: Verify `roles/artifactregistry.writer` is granted

**3. Workload Identity Authentication Failed**
```
Error: Unable to acquire impersonated credentials
```
Solution: Check the attribute condition matches your repository exactly

**4. Docker Build Context Error**
```
Error: nginx.conf not found
```
Solution: Ensure all files (Dockerfile, nginx.conf, .dockerignore) are in `angular_front_end/healthcare_plans_ui/`

### Useful Commands

```bash
# Check Cloud Run services
gcloud run services list --region=us-central1

# View service logs
gcloud run services logs read healthcare-plans-ui-dev --region=us-central1

# Get service URL
gcloud run services describe healthcare-plans-ui-dev --region=us-central1 --format="value(status.url)"

# List Artifact Registry images
gcloud artifacts docker images list us-central1-docker.pkg.dev/PROJECT_ID/healthcare-plans-ui
```

---

## Security Best Practices

1. **Use Workload Identity Federation** instead of service account keys
2. **Restrict the attribute condition** to only your repository
3. **Use least privilege** - only grant necessary IAM roles
4. **Rotate credentials** if using service account keys
5. **Enable audit logging** for Cloud Run deployments

---

## Cost Optimization

Cloud Run pricing is based on:
- CPU and memory allocation
- Request count
- Networking

Tips:
- Set `min-instances=0` to scale to zero when not in use
- Use appropriate memory/CPU settings (512Mi/1 CPU is usually sufficient for Angular apps)
- Consider using Cloud CDN for static assets

---

## Next Steps

- [ ] Set up custom domain mapping
- [ ] Configure Cloud CDN for better performance
- [ ] Add staging/production environment variables
- [ ] Set up monitoring and alerting
- [ ] Configure SSL certificates
