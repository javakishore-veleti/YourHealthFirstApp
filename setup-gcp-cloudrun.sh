#!/bin/bash

#############################################################################
# GCP Setup Script for GitHub Actions Cloud Run Deployment
# 
# This script creates all necessary GCP resources for deploying
# BOTH Angular UI and Flask Back Office from a SINGLE GitHub repository:
#
# Repository Structure:
#   YourHealthFirstApp/
#   ├── angular_front_end/healthcare_plans_ui/   (Angular UI)
#   └── python_flask_back_office/healthcare_plans_bo/  (Flask API)
#
# Resources Created:
# 1. Service Account with required permissions
# 2. TWO Artifact Registry repositories (one for UI, one for BO)
# 3. Workload Identity Federation for secure GitHub authentication
# 4. Optional: Service Account Key (JSON) for GitHub Secrets
#
# Prerequisites:
#   - gcloud CLI installed and authenticated
#   - Owner or Editor role on the GCP project
#   - Run this script from within the git repository
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
PROJECT_ID="engineering-college-apps"

# GCP Region for deployment
REGION="us-central1"

# Service Account name (will be created)
SERVICE_ACCOUNT_NAME="yourhealthplans-github-actions-cloudrun"

# Artifact Registry repository names (two repos for one GitHub repo)
# - UI repo: stores Angular Docker images
# - BO repo: stores Flask Docker images
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
    
    # Extract owner/repo from various URL formats
    local repo=""
    
    if [[ "$remote_url" =~ github\.com[:/]([^/]+/[^/]+?)(\.git)?$ ]]; then
        repo="${BASH_REMATCH[1]}"
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
echo "This will configure GCP for deploying BOTH:"
echo "  • Angular UI (angular_front_end/healthcare_plans_ui)"
echo "  • Flask BO (python_flask_back_office/healthcare_plans_bo)"
echo ""
echo "From a SINGLE GitHub repository."
echo ""
echo "Configuration:"
echo "  Project ID:        $PROJECT_ID"
echo "  Region:            $REGION"
echo "  Service Account:   $SERVICE_ACCOUNT_NAME"
echo "  GitHub Repo:       $GITHUB_REPO (auto-detected)"
echo ""
echo "Artifact Registries:"
echo "  UI Images:         $UI_ARTIFACT_REPO"
echo "  BO Images:         $BO_ARTIFACT_REPO"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Set the project
echo "📌 Step 1/8: Setting GCP project..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo ""
echo "📌 Step 2/8: Enabling required GCP APIs..."
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
echo "📌 Step 3/8: Creating Service Account..."
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" &>/dev/null; then
    echo "⚠️  Service Account already exists, skipping creation"
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="YourHealthPlans GitHub Actions Cloud Run Deployer" \
        --description="Service account for deploying Healthcare Plans UI and BO to Cloud Run from GitHub Actions"
    echo "✅ Service Account created: $SERVICE_ACCOUNT_EMAIL"
fi

# Grant required IAM roles to the Service Account
echo ""
echo "📌 Step 4/8: Granting IAM roles to Service Account..."

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
echo "📌 Step 5/8: Creating Artifact Registry repositories..."

# UI Repository (for Angular Docker images)
echo "  Creating UI repository: $UI_ARTIFACT_REPO"
if gcloud artifacts repositories describe $UI_ARTIFACT_REPO --location=$REGION &>/dev/null; then
    echo "  ⚠️  Repository $UI_ARTIFACT_REPO already exists, skipping"
else
    gcloud artifacts repositories create $UI_ARTIFACT_REPO \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker images for Healthcare Plans Angular UI"
    echo "  ✅ Repository $UI_ARTIFACT_REPO created"
fi

# BO Repository (for Flask Docker images)
echo "  Creating BO repository: $BO_ARTIFACT_REPO"
if gcloud artifacts repositories describe $BO_ARTIFACT_REPO --location=$REGION &>/dev/null; then
    echo "  ⚠️  Repository $BO_ARTIFACT_REPO already exists, skipping"
else
    gcloud artifacts repositories create $BO_ARTIFACT_REPO \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker images for Healthcare Plans Flask Back Office"
    echo "  ✅ Repository $BO_ARTIFACT_REPO created"
fi

# ============================================================================
# WORKLOAD IDENTITY FEDERATION SETUP
# ============================================================================

echo ""
echo "📌 Step 6/8: Setting up Workload Identity Federation..."

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
# CREATE SERVICE ACCOUNT KEY (JSON) FOR GITHUB SECRETS
# ============================================================================

echo ""
echo "📌 Step 7/8: Create Service Account Key (JSON)"
echo ""
echo "  You have two authentication options for GitHub Actions:"
echo ""
echo "  Option 1: Workload Identity Federation (More Secure - Recommended)"
echo "            - No JSON key needed"
echo "            - Uses OIDC tokens"
echo "            - Already configured above"
echo ""
echo "  Option 2: Service Account Key (JSON)"
echo "            - Download JSON key file"
echo "            - Store entire JSON content in GitHub Secret: GCP_SA_KEY"
echo "            - Simpler but less secure"
echo ""
read -p "Do you want to create/download a Service Account Key JSON? (y/n): " CREATE_KEY

if [[ "$CREATE_KEY" == "y" || "$CREATE_KEY" == "Y" ]]; then
    KEY_FILE="${SERVICE_ACCOUNT_NAME}-key.json"
    
    echo ""
    echo "📥 Creating and downloading Service Account Key..."
    gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account=$SERVICE_ACCOUNT_EMAIL
    
    echo ""
    echo "✅ Service Account Key saved to: $KEY_FILE"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 HOW TO ADD JSON KEY TO GITHUB SECRETS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  1. Open the file: $KEY_FILE"
    echo ""
    echo "  2. Copy the ENTIRE contents (including curly braces)"
    echo ""
    echo "  3. Go to GitHub repository secrets:"
    echo "     https://github.com/${GITHUB_REPO}/settings/secrets/actions"
    echo ""
    echo "  4. Click 'New repository secret'"
    echo ""
    echo "  5. Name: GCP_SA_KEY"
    echo "     Value: Paste the entire JSON content"
    echo ""
    echo "  6. Click 'Add secret'"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  SECURITY WARNINGS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  • DELETE the local JSON file after adding to GitHub Secrets!"
    echo "  • NEVER commit this file to your repository!"
    echo "  • Add '$KEY_FILE' to your .gitignore file!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Show preview of JSON file
    echo "📄 Preview of $KEY_FILE (first 5 lines):"
    echo "---"
    head -5 "$KEY_FILE"
    echo "..."
    echo "---"
fi

# ============================================================================
# UPDATE .gitignore
# ============================================================================

echo ""
echo "📌 Step 8/8: Updating .gitignore..."

GITIGNORE_ENTRIES=(
    "# GCP Service Account Keys - NEVER COMMIT THESE"
    "*-key.json"
    "*.json.key"
    "gcp-*.json"
    "*-sa-key.json"
)

if [[ -f ".gitignore" ]]; then
    # Check if already has the entry
    if ! grep -q "\*-key.json" .gitignore; then
        echo "" >> .gitignore
        for entry in "${GITIGNORE_ENTRIES[@]}"; do
            echo "$entry" >> .gitignore
        done
        echo "✅ Added GCP key patterns to .gitignore"
    else
        echo "⚠️  .gitignore already contains key patterns"
    fi
else
    for entry in "${GITIGNORE_ENTRIES[@]}"; do
        echo "$entry" >> .gitignore
    done
    echo "✅ Created .gitignore with GCP key patterns"
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
echo "┌─────────────────────────────────────────────────────────────────────┐"
echo "│ OPTION 1: Workload Identity Federation (Recommended)               │"
echo "├─────────────────────────────────────────────────────────────────────┤"
echo "│ GCP_PROJECT_ID                                                     │"
echo "│ $PROJECT_ID"
echo "│                                                                     │"
echo "│ GCP_SERVICE_ACCOUNT_EMAIL                                          │"
echo "│ $SERVICE_ACCOUNT_EMAIL"
echo "│                                                                     │"
echo "│ GCP_WORKLOAD_IDENTITY_PROVIDER                                     │"
echo "│ $WORKLOAD_IDENTITY_PROVIDER"
echo "└─────────────────────────────────────────────────────────────────────┘"
echo ""

if [[ "$CREATE_KEY" == "y" || "$CREATE_KEY" == "Y" ]]; then
    echo "┌─────────────────────────────────────────────────────────────────────┐"
    echo "│ OPTION 2: Service Account Key (Alternative)                        │"
    echo "├─────────────────────────────────────────────────────────────────────┤"
    echo "│ GCP_PROJECT_ID                                                     │"
    echo "│ $PROJECT_ID"
    echo "│                                                                     │"
    echo "│ GCP_SA_KEY                                                         │"
    echo "│ <Entire contents of $KEY_FILE>"
    echo "└─────────────────────────────────────────────────────────────────────┘"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 Useful Links"
echo ""
echo "  GitHub Secrets:"
echo "    https://github.com/${GITHUB_REPO}/settings/secrets/actions"
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

if [[ "$CREATE_KEY" == "y" || "$CREATE_KEY" == "Y" ]]; then
    echo ""
    echo "🔐 REMINDER: Delete the local key file after adding to GitHub!"
    echo "   rm $KEY_FILE"
    echo ""
fi
