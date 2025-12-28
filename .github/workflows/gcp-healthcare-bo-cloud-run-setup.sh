#!/bin/bash

#############################################################################
# GCP Setup Script for Flask Healthcare Plans Back Office - Cloud Run
# 
# This script creates the Artifact Registry repository for the Flask API.
# It assumes the Service Account and Workload Identity Federation are 
# already set up (shared with Angular UI).
#
# Prerequisites:
#   - gcloud CLI installed and authenticated
#   - Service Account already created (from Angular UI setup)
#
# Usage:
#   chmod +x gcp-healthcare-bo-cloud-run-setup.sh
#   ./gcp-healthcare-bo-cloud-run-setup.sh
#############################################################################

set -e

# ============================================================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================================================

PROJECT_ID="your-gcp-project-id"
REGION="us-central1"
ARTIFACT_REPO_NAME="healthcare-plans-bo"

# ============================================================================
# SCRIPT START
# ============================================================================

echo "=============================================="
echo "  GCP Cloud Run Setup"
echo "  Flask Healthcare Plans Back Office"
echo "=============================================="
echo ""
echo "Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Region:     $REGION"
echo "  Repository: $ARTIFACT_REPO_NAME"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Set the project
echo "📌 Setting GCP project..."
gcloud config set project $PROJECT_ID

# Create Artifact Registry repository for Flask Back Office
echo ""
echo "📌 Creating Artifact Registry repository..."
if gcloud artifacts repositories describe $ARTIFACT_REPO_NAME --location=$REGION &>/dev/null; then
    echo "⚠️  Artifact Registry repository already exists, skipping creation"
else
    gcloud artifacts repositories create $ARTIFACT_REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker images for Healthcare Plans Flask Back Office API"
    echo "✅ Artifact Registry repository created"
fi

# ============================================================================
# OUTPUT SUMMARY
# ============================================================================

echo ""
echo "=============================================="
echo "  ✅ SETUP COMPLETE!"
echo "=============================================="
echo ""
echo "📁 Place these files in your repository:"
echo ""
echo "  Docker Files (in python_flask_back_office/healthcare_plans_bo/):"
echo "    - Dockerfile"
echo "    - .dockerignore"
echo ""
echo "  GitHub Workflows (in .github/workflows/):"
echo "    - gcp-healthcare-bo-cloud-run-deploy.yml"
echo "    - gcp-healthcare-bo-cloud-run-stop.yml"
echo "    - gcp-healthcare-bo-cloud-run-restart.yml"
echo "    - gcp-healthcare-bo-cloud-run-health-check.yml"
echo "    - gcp-healthcare-bo-cloud-run-destroy.yml"
echo "    - gcp-healthcare-bo-cloud-run-status.yml"
echo ""
echo "🔗 Artifact Registry URL:"
echo "   ${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO_NAME}"
echo ""
echo "📝 Note: This setup uses the same GitHub Secrets as the Angular UI:"
echo "   - GCP_PROJECT_ID"
echo "   - GCP_SERVICE_ACCOUNT_EMAIL"
echo "   - GCP_WORKLOAD_IDENTITY_PROVIDER"
echo ""
echo "=============================================="
