#!/bin/bash

#############################################################################
# GCP Setup Script for Flask Healthcare Plans API - Cloud Run Deployment
# 
# This script creates all necessary GCP resources:
# 1. Service Account with required permissions
# 2. Artifact Registry repository for Docker images
# 3. Workload Identity Federation for secure GitHub authentication
#
# Prerequisites:
#   - gcloud CLI installed and authenticated
#   - Owner or Editor role on the GCP project
#
# Usage:
#   chmod +x gcp-healthcare-api-cloud-run-setup.sh
#   ./gcp-healthcare-api-cloud-run-setup.sh
#############################################################################

set -e  # Exit on any error

# ============================================================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================================================

# Your GCP Project ID
PROJECT_ID="your-gcp-project-id"

# GCP Region for deployment
REGION="us-central1"

# Service Account name (will be created)
SERVICE_ACCOUNT_NAME="github-actions-cloudrun"

# Artifact Registry repository name for Flask API
ARTIFACT_REPO_NAME="healthcare-plans-api"

# Your GitHub repository (format: owner/repo)
GITHUB_REPO="javakishore-veleti/YourHealthFirstApp"

# Workload Identity Pool name
POOL_NAME="github-actions-pool"

# Workload Identity Provider name
PROVIDER_NAME="github-actions-provider"

# ============================================================================
# SCRIPT START
# ============================================================================

echo "=============================================="
echo "  GCP Cloud Run Setup for GitHub Actions"
echo "  Flask Healthcare Plans API"
echo "=============================================="
echo ""
echo "Configuration:"
echo "  Project ID:   $PROJECT_ID"
echo "  Region:       $REGION"
echo "  GitHub Repo:  $GITHUB_REPO"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Set the project
echo "📌 Step 1/7: Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo ""
echo "📌 Step 2/7: Enabling required GCP APIs..."
gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    iamcredentials.googleapis.com \
    iam.googleapis.com \
    cloudresourcemanager.googleapis.com \
    sqladmin.googleapis.com

echo "✅ APIs enabled successfully"

# Create Service Account (if not exists)
echo ""
echo "📌 Step 3/7: Creating Service Account..."
if gcloud iam service-accounts describe "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" &>/dev/null; then
    echo "⚠️  Service Account already exists, skipping creation"
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="GitHub Actions Cloud Run Deployer" \
        --description="Service account for deploying Healthcare Plans API to Cloud Run"
    echo "✅ Service Account created"
fi

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant required IAM roles
echo ""
echo "📌 Step 4/7: Granting IAM roles to Service Account..."

ROLES=(
    "roles/run.admin"
    "roles/artifactregistry.writer"
    "roles/artifactregistry.reader"
    "roles/iam.serviceAccountUser"
    "roles/storage.admin"
    "roles/cloudsql.client"
)

for ROLE in "${ROLES[@]}"; do
    echo "  Adding $ROLE..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
        --role="$ROLE" \
        --quiet
done

echo "✅ IAM roles granted"

# Create Artifact Registry repository for Flask API
echo ""
echo "📌 Step 5/7: Creating Artifact Registry repository..."
if gcloud artifacts repositories describe $ARTIFACT_REPO_NAME --location=$REGION &>/dev/null; then
    echo "⚠️  Artifact Registry repository already exists, skipping creation"
else
    gcloud artifacts repositories create $ARTIFACT_REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker images for Healthcare Plans Flask API"
    echo "✅ Artifact Registry repository created"
fi

# Setup Workload Identity Federation
echo ""
echo "📌 Step 6/7: Setting up Workload Identity Federation..."

# Create Workload Identity Pool
echo "  Creating Workload Identity Pool..."
if gcloud iam workload-identity-pools describe $POOL_NAME --location="global" &>/dev/null; then
    echo "  ⚠️  Workload Identity Pool already exists, skipping creation"
else
    gcloud iam workload-identity-pools create $POOL_NAME \
        --location="global" \
        --display-name="GitHub Actions Pool" \
        --description="Identity pool for GitHub Actions CI/CD"
    echo "  ✅ Workload Identity Pool created"
fi

# Create Workload Identity Provider
echo "  Creating Workload Identity Provider..."
if gcloud iam workload-identity-pools providers describe $PROVIDER_NAME \
    --workload-identity-pool=$POOL_NAME \
    --location="global" &>/dev/null; then
    echo "  ⚠️  Workload Identity Provider already exists, skipping creation"
else
    gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
        --location="global" \
        --workload-identity-pool=$POOL_NAME \
        --display-name="GitHub Actions Provider" \
        --issuer-uri="https://token.actions.githubusercontent.com" \
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
        --attribute-condition="assertion.repository=='${GITHUB_REPO}'"
    echo "  ✅ Workload Identity Provider created"
fi

# Get the Workload Identity Provider resource name
WORKLOAD_IDENTITY_PROVIDER=$(gcloud iam workload-identity-pools providers describe $PROVIDER_NAME \
    --workload-identity-pool=$POOL_NAME \
    --location="global" \
    --format="value(name)")

# Get Project Number
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Allow GitHub to impersonate service account
echo "  Configuring service account impersonation..."
gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT_EMAIL \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_REPO}" \
    --quiet

echo "✅ Workload Identity Federation configured"

# Optional: Create Service Account Key
echo ""
echo "📌 Step 7/7: Service Account Key (Optional)"
read -p "Do you want to create a Service Account Key? (y/n): " CREATE_KEY
if [[ "$CREATE_KEY" == "y" || "$CREATE_KEY" == "Y" ]]; then
    KEY_FILE="gcp-healthcare-api-sa-key.json"
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SERVICE_ACCOUNT_EMAIL
    echo "✅ Service Account Key saved to: $KEY_FILE"
    echo ""
    echo "⚠️  SECURITY WARNING: Keep this key secure and delete after adding to GitHub Secrets"
fi

# ============================================================================
# OUTPUT SUMMARY
# ============================================================================

echo ""
echo "=============================================="
echo "  ✅ SETUP COMPLETE!"
echo "=============================================="
echo ""
echo "📋 GitHub Secrets Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Add these secrets to your GitHub repository:"
echo "  Repository → Settings → Secrets and variables → Actions"
echo ""
echo "┌────────────────────────────────────┬────────────────────────────────────────────┐"
echo "│ Secret Name                        │ Value                                      │"
echo "├────────────────────────────────────┼────────────────────────────────────────────┤"
printf "│ %-34s │ %-42s │\n" "GCP_PROJECT_ID" "$PROJECT_ID"
printf "│ %-34s │ %-42s │\n" "GCP_SERVICE_ACCOUNT_EMAIL" "$SERVICE_ACCOUNT_EMAIL"
echo "├────────────────────────────────────┼────────────────────────────────────────────┤"
echo "│ GCP_WORKLOAD_IDENTITY_PROVIDER     │ (see below - too long for table)           │"
echo "└────────────────────────────────────┴────────────────────────────────────────────┘"
echo ""
echo "GCP_WORKLOAD_IDENTITY_PROVIDER value:"
echo "$WORKLOAD_IDENTITY_PROVIDER"
echo ""

if [[ "$CREATE_KEY" == "y" || "$CREATE_KEY" == "Y" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Alternative: Service Account Key"
    echo ""
    echo "┌────────────────────────────────────┬────────────────────────────────────────────┐"
    printf "│ %-34s │ %-42s │\n" "GCP_SA_KEY" "Contents of $KEY_FILE"
    echo "└────────────────────────────────────┴────────────────────────────────────────────┘"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 GitHub Workflow Files (Flask API)"
echo ""
echo "Copy these files to .github/workflows/ in your repository:"
echo ""
echo "  1. gcp-healthcare-api-cloud-run-deploy.yml       - Deploy service"
echo "  2. gcp-healthcare-api-cloud-run-stop.yml         - Stop service"
echo "  3. gcp-healthcare-api-cloud-run-restart.yml      - Restart service"
echo "  4. gcp-healthcare-api-cloud-run-health-check.yml - Check health"
echo "  5. gcp-healthcare-api-cloud-run-destroy.yml      - Delete service"
echo "  6. gcp-healthcare-api-cloud-run-status.yml       - View all services"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 Useful Links"
echo ""
echo "  Artifact Registry:"
echo "    ${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO_NAME}"
echo ""
echo "  Cloud Run Console:"
echo "    https://console.cloud.google.com/run?project=${PROJECT_ID}"
echo ""
echo "  GitHub Actions:"
echo "    https://github.com/${GITHUB_REPO}/actions"
echo ""
echo "=============================================="
