<#
.SYNOPSIS
    GCP Setup Script for GitHub Actions Cloud Run Deployment (PowerShell)

.DESCRIPTION
    This script creates all necessary GCP resources:
    1. Service Account with required permissions
    2. Artifact Registry repositories for Docker images
    3. Workload Identity Federation for secure GitHub authentication

.PREREQUISITES
    - gcloud CLI installed and in PATH
    - Run: gcloud auth login
    - Owner or Editor role on the GCP project

.USAGE
    .\gcp-healthcare-cloud-run-setup.ps1

.NOTES
    Author: Healthcare Plans DevOps
    Version: 1.0
#>

# ============================================================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================================================

$CONFIG = @{
    ProjectId           = "your-gcp-project-id"
    Region              = "us-central1"
    ServiceAccountName  = "github-actions-cloudrun"
    GitHubRepo          = "javakishore-veleti/YourHealthFirstApp"
    PoolName            = "github-actions-pool"
    ProviderName        = "github-actions-provider"
    UIArtifactRepo      = "healthcare-plans-ui"
    BOArtifactRepo      = "healthcare-plans-bo"
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host "`n[$Step] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  SUCCESS: $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  WARNING: $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ERROR: $Message" -ForegroundColor Red
}

function Test-GCloudCommand {
    param([string]$Command)
    try {
        $null = Invoke-Expression "$Command 2>&1"
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Invoke-GCloud {
    param([string]$Command, [switch]$Silent)
    
    if ($Silent) {
        $result = Invoke-Expression "$Command 2>&1"
    }
    else {
        Invoke-Expression $Command
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "gcloud command failed: $Command"
    }
    
    return $result
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host @"

==============================================
  GCP Cloud Run Setup for GitHub Actions
  Healthcare Plans Application (PowerShell)
==============================================

Configuration:
  Project ID:   $($CONFIG.ProjectId)
  Region:       $($CONFIG.Region)
  GitHub Repo:  $($CONFIG.GitHubRepo)

"@ -ForegroundColor White

$confirmation = Read-Host "Press Enter to continue or Ctrl+C to cancel"

try {
    # Step 1: Set Project
    Write-Step "Step 1/7" "Setting GCP project..."
    Invoke-GCloud "gcloud config set project $($CONFIG.ProjectId)"
    Write-Success "Project set to $($CONFIG.ProjectId)"

    # Step 2: Enable APIs
    Write-Step "Step 2/7" "Enabling required GCP APIs..."
    $apis = @(
        "cloudbuild.googleapis.com"
        "run.googleapis.com"
        "artifactregistry.googleapis.com"
        "iamcredentials.googleapis.com"
        "iam.googleapis.com"
        "cloudresourcemanager.googleapis.com"
    )
    
    $apiList = $apis -join " "
    Invoke-GCloud "gcloud services enable $apiList"
    Write-Success "APIs enabled"

    # Step 3: Create Service Account
    Write-Step "Step 3/7" "Creating Service Account..."
    $serviceAccountEmail = "$($CONFIG.ServiceAccountName)@$($CONFIG.ProjectId).iam.gserviceaccount.com"
    
    $saExists = Test-GCloudCommand "gcloud iam service-accounts describe $serviceAccountEmail"
    
    if ($saExists) {
        Write-Warning "Service Account already exists, skipping creation"
    }
    else {
        Invoke-GCloud @"
gcloud iam service-accounts create $($CONFIG.ServiceAccountName) --display-name="GitHub Actions Cloud Run Deployer" --description="Service account for deploying Healthcare Plans to Cloud Run"
"@
        Write-Success "Service Account created: $serviceAccountEmail"
    }

    # Step 4: Grant IAM Roles
    Write-Step "Step 4/7" "Granting IAM roles to Service Account..."
    $roles = @(
        "roles/run.admin"
        "roles/artifactregistry.writer"
        "roles/artifactregistry.reader"
        "roles/iam.serviceAccountUser"
        "roles/storage.admin"
    )
    
    foreach ($role in $roles) {
        Write-Host "    Adding $role..." -ForegroundColor Gray
        Invoke-GCloud "gcloud projects add-iam-policy-binding $($CONFIG.ProjectId) --member=serviceAccount:$serviceAccountEmail --role=$role --quiet" -Silent
    }
    Write-Success "IAM roles granted"

    # Step 5: Create Artifact Registry Repositories
    Write-Step "Step 5/7" "Creating Artifact Registry repositories..."
    
    # UI Repository
    $uiRepoExists = Test-GCloudCommand "gcloud artifacts repositories describe $($CONFIG.UIArtifactRepo) --location=$($CONFIG.Region)"
    if ($uiRepoExists) {
        Write-Warning "Repository $($CONFIG.UIArtifactRepo) already exists, skipping"
    }
    else {
        Invoke-GCloud "gcloud artifacts repositories create $($CONFIG.UIArtifactRepo) --repository-format=docker --location=$($CONFIG.Region) --description=`"Docker images for Healthcare Plans Angular UI`""
        Write-Success "Repository $($CONFIG.UIArtifactRepo) created"
    }
    
    # BO Repository
    $boRepoExists = Test-GCloudCommand "gcloud artifacts repositories describe $($CONFIG.BOArtifactRepo) --location=$($CONFIG.Region)"
    if ($boRepoExists) {
        Write-Warning "Repository $($CONFIG.BOArtifactRepo) already exists, skipping"
    }
    else {
        Invoke-GCloud "gcloud artifacts repositories create $($CONFIG.BOArtifactRepo) --repository-format=docker --location=$($CONFIG.Region) --description=`"Docker images for Healthcare Plans Flask Back Office`""
        Write-Success "Repository $($CONFIG.BOArtifactRepo) created"
    }

    # Step 6: Setup Workload Identity Federation
    Write-Step "Step 6/7" "Setting up Workload Identity Federation..."
    
    # Create Workload Identity Pool
    Write-Host "    Creating Workload Identity Pool..." -ForegroundColor Gray
    $poolExists = Test-GCloudCommand "gcloud iam workload-identity-pools describe $($CONFIG.PoolName) --location=global"
    
    if ($poolExists) {
        Write-Warning "Workload Identity Pool already exists, skipping"
    }
    else {
        Invoke-GCloud "gcloud iam workload-identity-pools create $($CONFIG.PoolName) --location=global --display-name=`"GitHub Actions Pool`" --description=`"Identity pool for GitHub Actions CI/CD`""
        Write-Success "Workload Identity Pool created"
    }
    
    # Create Workload Identity Provider
    Write-Host "    Creating Workload Identity Provider..." -ForegroundColor Gray
    $providerExists = Test-GCloudCommand "gcloud iam workload-identity-pools providers describe $($CONFIG.ProviderName) --workload-identity-pool=$($CONFIG.PoolName) --location=global"
    
    if ($providerExists) {
        Write-Warning "Workload Identity Provider already exists, skipping"
    }
    else {
        Invoke-GCloud @"
gcloud iam workload-identity-pools providers create-oidc $($CONFIG.ProviderName) --location=global --workload-identity-pool=$($CONFIG.PoolName) --display-name="GitHub Actions Provider" --issuer-uri="https://token.actions.githubusercontent.com" --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" --attribute-condition="assertion.repository=='$($CONFIG.GitHubRepo)'"
"@
        Write-Success "Workload Identity Provider created"
    }
    
    # Get Workload Identity Provider full name
    Write-Host "    Getting Workload Identity Provider resource name..." -ForegroundColor Gray
    $workloadIdentityProvider = Invoke-GCloud "gcloud iam workload-identity-pools providers describe $($CONFIG.ProviderName) --workload-identity-pool=$($CONFIG.PoolName) --location=global --format=`"value(name)`"" -Silent
    $workloadIdentityProvider = $workloadIdentityProvider.Trim()
    
    # Get Project Number
    $projectNumber = Invoke-GCloud "gcloud projects describe $($CONFIG.ProjectId) --format=`"value(projectNumber)`"" -Silent
    $projectNumber = $projectNumber.Trim()
    
    # Configure service account impersonation
    Write-Host "    Configuring service account impersonation..." -ForegroundColor Gray
    $member = "principalSet://iam.googleapis.com/projects/$projectNumber/locations/global/workloadIdentityPools/$($CONFIG.PoolName)/attribute.repository/$($CONFIG.GitHubRepo)"
    Invoke-GCloud "gcloud iam service-accounts add-iam-policy-binding $serviceAccountEmail --role=roles/iam.workloadIdentityUser --member=`"$member`" --quiet" -Silent
    Write-Success "Workload Identity Federation configured"

    # Step 7: Optional Service Account Key
    Write-Step "Step 7/7" "Service Account Key (Optional)"
    $createKey = Read-Host "Do you want to create a Service Account Key? (y/n)"
    
    $keyFile = $null
    if ($createKey -eq 'y' -or $createKey -eq 'Y') {
        $keyFile = "gcp-healthcare-sa-key.json"
        Invoke-GCloud "gcloud iam service-accounts keys create $keyFile --iam-account=$serviceAccountEmail"
        Write-Success "Service Account Key saved to: $keyFile"
        Write-Host ""
        Write-Host "  WARNING: Keep this key secure and delete after adding to GitHub Secrets!" -ForegroundColor Yellow
    }

    # ============================================================================
    # OUTPUT SUMMARY
    # ============================================================================
    
    Write-Host @"

==============================================
  SETUP COMPLETE!
==============================================

GitHub Secrets Configuration
----------------------------------------------
Add these secrets to your GitHub repository:
  Repository -> Settings -> Secrets and variables -> Actions

"@ -ForegroundColor Green

    # Create a table for secrets
    $secrets = @(
        [PSCustomObject]@{ Name = "GCP_PROJECT_ID"; Value = $CONFIG.ProjectId }
        [PSCustomObject]@{ Name = "GCP_SERVICE_ACCOUNT_EMAIL"; Value = $serviceAccountEmail }
        [PSCustomObject]@{ Name = "GCP_WORKLOAD_IDENTITY_PROVIDER"; Value = $workloadIdentityProvider }
    )
    
    $secrets | Format-Table -AutoSize
    
    if ($keyFile) {
        Write-Host "Alternative - Service Account Key:" -ForegroundColor Yellow
        Write-Host "  GCP_SA_KEY = Contents of $keyFile" -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host @"
----------------------------------------------
Artifact Registry URLs:
  UI:  $($CONFIG.Region)-docker.pkg.dev/$($CONFIG.ProjectId)/$($CONFIG.UIArtifactRepo)
  BO:  $($CONFIG.Region)-docker.pkg.dev/$($CONFIG.ProjectId)/$($CONFIG.BOArtifactRepo)

Cloud Run Console:
  https://console.cloud.google.com/run?project=$($CONFIG.ProjectId)

GitHub Actions:
  https://github.com/$($CONFIG.GitHubRepo)/actions
==============================================
"@ -ForegroundColor White

    # Copy to clipboard option
    $copyToClipboard = Read-Host "`nWould you like to copy the secrets to clipboard? (y/n)"
    if ($copyToClipboard -eq 'y' -or $copyToClipboard -eq 'Y') {
        $clipboardText = @"
GCP_PROJECT_ID=$($CONFIG.ProjectId)
GCP_SERVICE_ACCOUNT_EMAIL=$serviceAccountEmail
GCP_WORKLOAD_IDENTITY_PROVIDER=$workloadIdentityProvider
"@
        Set-Clipboard -Value $clipboardText
        Write-Success "Secrets copied to clipboard!"
    }
}
catch {
    Write-Error $_.Exception.Message
    Write-Host "`nSetup failed. Please check the error above and try again." -ForegroundColor Red
    exit 1
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
