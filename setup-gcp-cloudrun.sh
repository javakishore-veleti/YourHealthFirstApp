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
#   - Run this script from within a git repository
#
# Usage:
#   chmod +x gcp-healthcare-cloud-run-setup.sh
#   ./gcp-healthcare-cloud-run-setup.sh
#############################################################################

set -e  # Exit on any error

# ============================================================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================================================

# Your GCP Project ID
PROJECT_ID="engineering-college-apps"

# GCP Region for deployment
REGION="us-central1"

# Service Account name (will be created)
SERVICE_ACCOUNT_NAME="github-actions-cloudrun"

# Artifact Registry repository names
UI_ARTIFACT_REPO="healthcare-plans-ui"
BO_ARTIFACT_REPO="healthcare-plans-bo"

# Workload Identity Pool name
POOL_NAME="github-actions-pool"

# Workload Identity Provider name
PROVIDER_NAME="github-actions-provider"

# ============================================================================
# AUTO-DETECT GITHUB REPOSITORY
# ============================================================================

detect_github_repo() {
    local remote_url=""
    
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo ""
        return 1
    fi
    
    # Try to get the remote URL (prefer origin)
    remote_url=$(git remote get-url origin 2>/dev/null || git remote get-url $(git remote | head -1) 2>/dev/null || echo "")
    
    if [[ -z "$remote_url" ]]; then
        echo ""
        return 1
    fi
    
    # Extract owner/repo from various URL formats:
    # - https://github.com/owner/repo.git
    # - https://github.com/owner/repo
    # - git@github.com:owner/repo.git
    # - git@github.com:owner/repo
    
    local repo=""
    
    if [[ "$remote_url" =~ github\.com[:/]([^/]+/[^/]+?)(\.git)?$ ]]; then
        repo="${BASH_REMATCH[1]}"
        # Remove .git suffix if present
        repo="${repo%.git}"
    fi
    
    echo "$repo"
}

# Auto-detect or prompt for GitHub repo
GITHUB_REPO=$(detect_github_repo)

if [[ -z "$GITHUB_REPO" ]]; then
    echo "⚠️  Could not auto-detect GitHub repository."
    echo "    Make sure you're running this script from within the git repository."
    echo ""
    read -p "Enter GitHub repository (format: owner/repo): " GITHUB_REPO
    
    if [[ -z "$GITHUB_REPO" ]]; then
        echo "❌ GitHub repository is required. Exiting."
        exit 1
    fi
fi

# ============================================================================
# SCRIPT START
# ============================================================================

echo "=============================================="
echo "GCP Cloud Run Setup for GitHub Actions"
echo "=============================================="
echo ""
echo "Project ID:   $PROJECT_ID"
echo "Region:       $REGION"
echo "GitHub Repo:  $GITHUB_REPO (auto-detected)"
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
    cloudresourcemanager.googleapis.com

echo "✅ APIs enabled successfully"

# Create Service Account
echo ""
echo "📌 Step 3/7: Creating Service Account..."
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" &>/dev/null; then
    echo "⚠️  Service Account already exists, skipping creation"
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="GitHub Actions Cloud Run Deployer" \
        --description="Service account for deploying to Cloud Run from GitHub Actions"
    echo "✅ Service Account created"
fi

# Grant required IAM roles to the Service Account
echo ""
echo "📌 Step 4/7: Granting IAM roles to Service Account..."

ROLES=(
    "roles/run.admin"
    "roles/artifactregistry.writer"
    "roles/artifactregistry.reader"
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

# Create Artifact Registry repositories
echo ""
echo "📌 Step 5/7: Creating Artifact Registry repositories..."

# UI Repository
if gcloud artifacts repositories describe $UI_ARTIFACT_REPO --location=$REGION &>/dev/null; then
    echo "⚠️  Repository $UI_ARTIFACT_REPO already exists, skipping"
else
    gcloud artifacts repositories create $UI_ARTIFACT_REPO \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker images for Healthcare Plans Angular UI"
    echo "✅ Repository $UI_ARTIFACT_REPO created"
fi

# BO Repository
if gcloud artifacts repositories describe $BO_ARTIFACT_REPO --location=$REGION &>/dev/null; then
    echo "⚠️  Repository $BO_ARTIFACT_REPO already exists, skipping"
else
    gcloud artifacts repositories create $BO_ARTIFACT_REPO \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker images for Healthcare Plans Flask Back Office"
    echo "✅ Repository $BO_ARTIFACT_REPO created"
fi

# ============================================================================
# WORKLOAD IDENTITY FEDERATION SETUP
# ============================================================================

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

# Get Project Number
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Allow the GitHub repo to impersonate the service account
echo "  Configuring service account impersonation..."
gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT_EMAIL \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_REPO}" \
    --quiet

echo "✅ Workload Identity Federation configured"

# ============================================================================
# OPTIONAL: CREATE SERVICE ACCOUNT KEY
# ============================================================================

echo ""
echo "📌 Step 7/7: Service Account Key (Optional)"
read -p "Do you want to create a Service Account Key? (y/n): " CREATE_KEY
if [[ "$CREATE_KEY" == "y" || "$CREATE_KEY" == "Y" ]]; then
    KEY_FILE="gcp-healthcare-sa-key.json"
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SERVICE_ACCOUNT_EMAIL
    echo "✅ Service Account Key saved to: $KEY_FILE"
    echo ""
    echo "⚠️  SECURITY WARNING: Keep this key secure and delete after adding to GitHub Secrets!"
fi

# ============================================================================
# OUTPUT SUMMARY
# ============================================================================

echo ""
echo "=============================================="
echo "✅ SETUP COMPLETE!"
echo "=============================================="
echo ""
echo "📋 GitHub Secrets Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Add these secrets to your GitHub repository:"
echo "  https://github.com/${GITHUB_REPO}/settings/secrets/actions"
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
echo "🔗 Useful Links"
echo ""
echo "  Artifact Registry (UI):"
echo "    ${REGION}-docker.pkg.dev/${PROJECT_ID}/${UI_ARTIFACT_REPO}"
echo ""
echo "  Artifact Registry (BO):"
echo "    ${REGION}-docker.pkg.dev/${PROJECT_ID}/${BO_ARTIFACT_REPO}"
echo ""
echo "  Cloud Run Console:"
echo "    https://console.cloud.google.com/run?project=${PROJECT_ID}"
echo ""
echo "  GitHub Actions:"
echo "    https://github.com/${GITHUB_REPO}/actions"
echo ""
echo "=============================================="
