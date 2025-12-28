#!/bin/bash

#############################################################################
# GCP Setup Script for GitHub Actions Cloud Run Deployment
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
#   chmod +x setup-gcp-cloudrun.sh
#   ./setup-gcp-cloudrun.sh
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

# Artifact Registry repository name
ARTIFACT_REPO_NAME="healthcare-plans-ui"

# Your GitHub repository (format: owner/repo)
GITHUB_REPO="javakishore-veleti/YourHealthFirstApp"

# Workload Identity Pool name
POOL_NAME="github-actions-pool"

# Workload Identity Provider name
PROVIDER_NAME="github-actions-provider"

# ============================================================================
# SCRIPT START - DO NOT MODIFY BELOW UNLESS NECESSARY
# ============================================================================

echo "=============================================="
echo "GCP Cloud Run Setup for GitHub Actions"
echo "=============================================="
echo ""
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "GitHub Repo: $GITHUB_REPO"
echo ""

# Set the project
echo "📌 Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo ""
echo "📌 Enabling required GCP APIs..."
gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    iamcredentials.googleapis.com \
    iam.googleapis.com \
    cloudresourcemanager.googleapis.com

echo "✅ APIs enabled successfully"

# Create Service Account
echo ""
echo "📌 Creating Service Account..."
if gcloud iam service-accounts describe "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" &>/dev/null; then
    echo "⚠️  Service Account already exists, skipping creation"
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="GitHub Actions Cloud Run Deployer" \
        --description="Service account for deploying to Cloud Run from GitHub Actions"
    echo "✅ Service Account created"
fi

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant required IAM roles to the Service Account
echo ""
echo "📌 Granting IAM roles to Service Account..."

ROLES=(
    "roles/run.admin"
    "roles/artifactregistry.writer"
    "roles/iam.serviceAccountUser"
    "roles/storage.admin"
)

for ROLE in "${ROLES[@]}"; do
    echo "  Adding $ROLE..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
        --role="$ROLE" \
        --quiet
done

echo "✅ IAM roles granted"

# Create Artifact Registry repository
echo ""
echo "📌 Creating Artifact Registry repository..."
if gcloud artifacts repositories describe $ARTIFACT_REPO_NAME --location=$REGION &>/dev/null; then
    echo "⚠️  Artifact Registry repository already exists, skipping creation"
else
    gcloud artifacts repositories create $ARTIFACT_REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker images for Healthcare Plans UI"
    echo "✅ Artifact Registry repository created"
fi

# ============================================================================
# WORKLOAD IDENTITY FEDERATION SETUP (Recommended - More Secure)
# ============================================================================

echo ""
echo "📌 Setting up Workload Identity Federation..."

# Create Workload Identity Pool
echo "  Creating Workload Identity Pool..."
if gcloud iam workload-identity-pools describe $POOL_NAME --location="global" &>/dev/null; then
    echo "  ⚠️  Workload Identity Pool already exists, skipping creation"
else
    gcloud iam workload-identity-pools create $POOL_NAME \
        --location="global" \
        --display-name="GitHub Actions Pool" \
        --description="Identity pool for GitHub Actions"
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

# Allow the GitHub repo to impersonate the service account
echo "  Configuring service account impersonation..."
gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT_EMAIL \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_PROVIDER}/attribute.repository/${GITHUB_REPO}" \
    --quiet

echo "✅ Workload Identity Federation configured"

# ============================================================================
# OPTIONAL: CREATE SERVICE ACCOUNT KEY (Less secure alternative)
# ============================================================================

echo ""
read -p "Do you also want to create a Service Account Key? (y/n): " CREATE_KEY
if [[ "$CREATE_KEY" == "y" || "$CREATE_KEY" == "Y" ]]; then
    echo "📌 Creating Service Account Key..."
    KEY_FILE="github-actions-sa-key.json"
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SERVICE_ACCOUNT_EMAIL
    echo "✅ Service Account Key saved to: $KEY_FILE"
    echo ""
    echo "⚠️  IMPORTANT: Keep this key secure and delete it after adding to GitHub Secrets!"
fi

# ============================================================================
# OUTPUT SUMMARY
# ============================================================================

echo ""
echo "=============================================="
echo "✅ SETUP COMPLETE!"
echo "=============================================="
echo ""
echo "📋 Add these secrets to your GitHub repository:"
echo "   (Go to: Settings → Secrets and variables → Actions → New repository secret)"
echo ""
echo "┌─────────────────────────────────────────────────────────────────────────┐"
echo "│ SECRET NAME                      │ VALUE                                │"
echo "├─────────────────────────────────────────────────────────────────────────┤"
echo "│ GCP_PROJECT_ID                   │ $PROJECT_ID"
echo "│ GCP_SERVICE_ACCOUNT_EMAIL        │ $SERVICE_ACCOUNT_EMAIL"
echo "│ GCP_WORKLOAD_IDENTITY_PROVIDER   │ $WORKLOAD_IDENTITY_PROVIDER"
echo "└─────────────────────────────────────────────────────────────────────────┘"
echo ""
if [[ "$CREATE_KEY" == "y" || "$CREATE_KEY" == "Y" ]]; then
    echo "If using Service Account Key instead of Workload Identity:"
    echo "┌─────────────────────────────────────────────────────────────────────────┐"
    echo "│ GCP_SA_KEY                       │ Contents of $KEY_FILE (JSON)        │"
    echo "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""
fi
echo "📝 Artifact Registry URL:"
echo "   ${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO_NAME}"
echo ""
echo "🔗 Cloud Run Console:"
echo "   https://console.cloud.google.com/run?project=${PROJECT_ID}"
echo ""
echo "=============================================="
