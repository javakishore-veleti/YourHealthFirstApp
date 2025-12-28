<#
.SYNOPSIS
    GCP Setup Script for GitHub Actions Cloud Run Deployment (PowerShell)

.DESCRIPTION
    This script creates all necessary GCP resources for deploying
    BOTH Angular UI and Flask Back Office from a SINGLE GitHub repository:

    Repository Structure:
      YourHealthFirstApp/
      ├── angular_front_end/healthcare_plans_ui/   (Angular UI)
      └── python_flask_back_office/healthcare_plans_bo/  (Flask API)

    Resources Created:
    1. Service Account with required permissions
    2. TWO Artifact Registry repositories (one for UI, one for BO)
    3. Workload Identity Federation for secure GitHub authentication
    4. Optional: Service Account Key (JSON) for GitHub Secrets

.PREREQUISITES
    - gcloud CLI installed and in PATH
    - git installed and in PATH
    - Run: gcloud auth login
    - Owner or Editor role on the GCP project

.USAGE
    .\setup-gcp-cloud-run.ps1
#>

# ============================================================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================================================

$CONFIG = @{
    ProjectId           = "engineering-college-apps"
    Region              = "us-central1"
    ServiceAccountName  = "yourhealthplans-github-actions-cloudrun"
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

function Write-Warn {
    param([string]$Message)
    Write-Host "  WARNING: $Message" -ForegroundColor Yellow
}

function Write-Err {
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

function Get-GitHubRepoFromRemote {
    try {
        $null = git rev-parse --is-inside-work-tree 2>&1
        if ($LASTEXITCODE -ne 0) { return $null }
    }
    catch { return $null }
    
    $remoteUrl = $null
    try {
        $remoteUrl = git remote get-url origin 2>&1
        if ($LASTEXITCODE -ne 0) {
            $remotes = git remote 2>&1
            if ($remotes -and $LASTEXITCODE -eq 0) {
                $firstRemote = ($remotes -split "`n")[0]
                $remoteUrl = git remote get-url $firstRemote 2>&1
            }
        }
    }
    catch { return $null }
    
    if (-not $remoteUrl -or $LASTEXITCODE -ne 0) { return $null }
    
    $remoteUrl = $remoteUrl.Trim()
    $repo = $null
    
    if ($remoteUrl -match 'https://github\.com/([^/]+/[^/]+?)(?:\.git)?$') {
        $repo = $matches[1]
    }
    elseif ($remoteUrl -match 'git@github\.com:([^/]+/[^/]+?)(?:\.git)?$') {
        $repo = $matches[1]
    }
    
    if ($repo) { $repo = $repo -replace '\.git$', '' }
    
    return $repo
}

# ============================================================================
# AUTO-DETECT GITHUB REPOSITORY
# ============================================================================

Write-Host "Detecting GitHub repository..." -ForegroundColor Gray

$GitHubRepo = Get-GitHubRepoFromRemote

if (-not $GitHubRepo) {
    Write-Warn "Could not auto-detect GitHub repository."
    $GitHubRepo = Read-Host "Enter GitHub repository (format: owner/repo)"
    
    if (-not $GitHubRepo) {
        Write-Err "GitHub repository is required. Exiting."
        exit 1
    }
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host @"

==============================================
  GCP Cloud Run Setup for GitHub Actions
==============================================

This will configure GCP for deploying BOTH:
  * Angular UI (angular_front_end/healthcare_plans_ui)
  * Flask BO (python_flask_back_office/healthcare_plans_bo)

From a SINGLE GitHub repository.

Configuration:
  Project ID:        $($CONFIG.ProjectId)
  Region:            $($CONFIG.Region)
  Service Account:   $($CONFIG.ServiceAccountName)
  GitHub Repo:       $GitHubRepo (auto-detected)

Artifact Registries:
  UI Images:         $($CONFIG.UIArtifactRepo)
  BO Images:         $($CONFIG.BOArtifactRepo)

"@ -ForegroundColor White

$confirmation = Read-Host "Press Enter to continue or Ctrl+C to cancel"

try {
    # Step 1: Set Project
    Write-Step "Step 1/8" "Setting GCP project..."
    Invoke-GCloud "gcloud config set project $($CONFIG.ProjectId)"
    Write-Success "Project set to $($CONFIG.ProjectId)"

    # Step 2: Enable APIs
    Write-Step "Step 2/8" "Enabling required GCP APIs..."
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
    Write-Step "Step 3/8" "Creating Service Account..."
    $serviceAccountEmail = "$($CONFIG.ServiceAccountName)@$($CONFIG.ProjectId).iam.gserviceaccount.com"
    
    $saExists = Test-GCloudCommand "gcloud iam service-accounts describe $serviceAccountEmail"
    
    if ($saExists) {
        Write-Warn "Service Account already exists, skipping creation"
    }
    else {
        Invoke-GCloud "gcloud iam service-accounts create $($CONFIG.ServiceAccountName) --display-name=`"YourHealthPlans GitHub Actions Cloud Run Deployer`" --description=`"Service account for deploying Healthcare Plans UI and BO to Cloud Run`""
        Write-Success "Service Account created: $serviceAccountEmail"
    }

    # Step 4: Grant IAM Roles
    Write-Step "Step 4/8" "Granting IAM roles to Service Account..."
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
    Write-Step "Step 5/8" "Creating Artifact Registry repositories..."
    
    # UI Repository
    Write-Host "    Creating UI repository: $($CONFIG.UIArtifactRepo)" -ForegroundColor Gray
    $uiRepoExists = Test-GCloudCommand "gcloud artifacts repositories describe $($CONFIG.UIArtifactRepo) --location=$($CONFIG.Region)"
    if ($uiRepoExists) {
        Write-Warn "Repository $($CONFIG.UIArtifactRepo) already exists, skipping"
    }
    else {
        Invoke-GCloud "gcloud artifacts repositories create $($CONFIG.UIArtifactRepo) --repository-format=docker --location=$($CONFIG.Region) --description=`"Docker images for Healthcare Plans Angular UI`""
        Write-Success "Repository $($CONFIG.UIArtifactRepo) created"
    }
    
    # BO Repository
    Write-Host "    Creating BO repository: $($CONFIG.BOArtifactRepo)" -ForegroundColor Gray
    $boRepoExists = Test-GCloudCommand "gcloud artifacts repositories describe $($CONFIG.BOArtifactRepo) --location=$($CONFIG.Region)"
    if ($boRepoExists) {
        Write-Warn "Repository $($CONFIG.BOArtifactRepo) already exists, skipping"
    }
    else {
        Invoke-GCloud "gcloud artifacts repositories create $($CONFIG.BOArtifactRepo) --repository-format=docker --location=$($CONFIG.Region) --description=`"Docker images for Healthcare Plans Flask Back Office`""
        Write-Success "Repository $($CONFIG.BOArtifactRepo) created"
    }

    # Step 6: Setup Workload Identity Federation
    Write-Step "Step 6/8" "Setting up Workload Identity Federation..."
    
    Write-Host "    Creating Workload Identity Pool..." -ForegroundColor Gray
    $poolExists = Test-GCloudCommand "gcloud iam workload-identity-pools describe $($CONFIG.PoolName) --location=global"
    
    if ($poolExists) {
        Write-Warn "Workload Identity Pool already exists, skipping"
    }
    else {
        Invoke-GCloud "gcloud iam workload-identity-pools create $($CONFIG.PoolName) --location=global --display-name=`"GitHub Actions Pool`" --description=`"Identity pool for GitHub Actions CI/CD`""
        Write-Success "Workload Identity Pool created"
    }
    
    Write-Host "    Creating Workload Identity Provider..." -ForegroundColor Gray
    $providerExists = Test-GCloudCommand "gcloud iam workload-identity-pools providers describe $($CONFIG.ProviderName) --workload-identity-pool=$($CONFIG.PoolName) --location=global"
    
    if ($providerExists) {
        Write-Warn "Workload Identity Provider already exists, skipping"
    }
    else {
        Invoke-GCloud "gcloud iam workload-identity-pools providers create-oidc $($CONFIG.ProviderName) --location=global --workload-identity-pool=$($CONFIG.PoolName) --display-name=`"GitHub Actions Provider`" --issuer-uri=`"https://token.actions.githubusercontent.com`" --attribute-mapping=`"google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner`" --attribute-condition=`"assertion.repository=='$GitHubRepo'`""
        Write-Success "Workload Identity Provider created"
    }
    
    Write-Host "    Getting Workload Identity Provider resource name..." -ForegroundColor Gray
    $workloadIdentityProvider = Invoke-GCloud "gcloud iam workload-identity-pools providers describe $($CONFIG.ProviderName) --workload-identity-pool=$($CONFIG.PoolName) --location=global --format=`"value(name)`"" -Silent
    $workloadIdentityProvider = $workloadIdentityProvider.Trim()
    
    $projectNumber = Invoke-GCloud "gcloud projects describe $($CONFIG.ProjectId) --format=`"value(projectNumber)`"" -Silent
    $projectNumber = $projectNumber.Trim()
    
    Write-Host "    Configuring service account impersonation..." -ForegroundColor Gray
    $member = "principalSet://iam.googleapis.com/projects/$projectNumber/locations/global/workloadIdentityPools/$($CONFIG.PoolName)/attribute.repository/$GitHubRepo"
    Invoke-GCloud "gcloud iam service-accounts add-iam-policy-binding $serviceAccountEmail --role=roles/iam.workloadIdentityUser --member=`"$member`" --quiet" -Silent
    Write-Success "Workload Identity Federation configured"

    # Step 7: Create Service Account Key
    Write-Step "Step 7/8" "Create Service Account Key (JSON)"
    
    Write-Host @"

  You have two authentication options for GitHub Actions:

  Option 1: Workload Identity Federation (More Secure - Recommended)
            - No JSON key needed
            - Uses OIDC tokens

  Option 2: Service Account Key (JSON)
            - Download JSON key file
            - Store entire JSON in GitHub Secret: GCP_SA_KEY

"@ -ForegroundColor White

    $createKey = Read-Host "Do you want to create/download a Service Account Key JSON? (y/n)"
    
    $keyFile = $null
    if ($createKey -eq 'y' -or $createKey -eq 'Y') {
        $keyFile = "$($CONFIG.ServiceAccountName)-key.json"
        
        Write-Host "`nCreating and downloading Service Account Key..." -ForegroundColor Gray
        Invoke-GCloud "gcloud iam service-accounts keys create $keyFile --iam-account=$serviceAccountEmail"
        
        Write-Success "Service Account Key saved to: $keyFile"
        
        Write-Host @"

==================================================================
HOW TO ADD JSON KEY TO GITHUB SECRETS:
==================================================================

  1. Open the file: $keyFile

  2. Copy the ENTIRE contents (including curly braces)

  3. Go to GitHub repository secrets:
     https://github.com/$GitHubRepo/settings/secrets/actions

  4. Click 'New repository secret'

  5. Name: GCP_SA_KEY
     Value: Paste the entire JSON content

  6. Click 'Add secret'

==================================================================
SECURITY WARNINGS:
==================================================================
  * DELETE the local JSON file after adding to GitHub Secrets!
  * NEVER commit this file to your repository!
  * Add '$keyFile' to your .gitignore file!
==================================================================
"@ -ForegroundColor Yellow
        
        # Show preview
        Write-Host "`nPreview of $keyFile (first 5 lines):" -ForegroundColor Gray
        Get-Content $keyFile -Head 5
        Write-Host "..."
    }

    # Step 8: Update .gitignore
    Write-Step "Step 8/8" "Updating .gitignore..."
    
    $gitignoreEntries = @"

# GCP Service Account Keys - NEVER COMMIT THESE
*-key.json
*.json.key
gcp-*.json
*-sa-key.json
"@

    if (Test-Path ".gitignore") {
        $gitignoreContent = Get-Content ".gitignore" -Raw
        if ($gitignoreContent -notmatch '\*-key\.json') {
            Add-Content ".gitignore" $gitignoreEntries
            Write-Success "Added GCP key patterns to .gitignore"
        }
        else {
            Write-Warn ".gitignore already contains key patterns"
        }
    }
    else {
        Set-Content ".gitignore" $gitignoreEntries
        Write-Success "Created .gitignore with GCP key patterns"
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
Add these secrets at:
  https://github.com/$GitHubRepo/settings/secrets/actions

"@ -ForegroundColor Green

    Write-Host "OPTION 1: Workload Identity Federation (Recommended)" -ForegroundColor Cyan
    Write-Host "----------------------------------------------" -ForegroundColor Gray
    
    $secrets = @(
        [PSCustomObject]@{ Name = "GCP_PROJECT_ID"; Value = $CONFIG.ProjectId }
        [PSCustomObject]@{ Name = "GCP_SERVICE_ACCOUNT_EMAIL"; Value = $serviceAccountEmail }
        [PSCustomObject]@{ Name = "GCP_WORKLOAD_IDENTITY_PROVIDER"; Value = $workloadIdentityProvider }
    )
    $secrets | Format-Table -AutoSize
    
    if ($keyFile) {
        Write-Host "OPTION 2: Service Account Key (Alternative)" -ForegroundColor Yellow
        Write-Host "----------------------------------------------" -ForegroundColor Gray
        Write-Host "GCP_PROJECT_ID = $($CONFIG.ProjectId)"
        Write-Host "GCP_SA_KEY = <Entire contents of $keyFile>"
        Write-Host ""
    }

    Write-Host @"
----------------------------------------------
Artifact Registry URLs:
  UI: $($CONFIG.Region)-docker.pkg.dev/$($CONFIG.ProjectId)/$($CONFIG.UIArtifactRepo)
  BO: $($CONFIG.Region)-docker.pkg.dev/$($CONFIG.ProjectId)/$($CONFIG.BOArtifactRepo)

Cloud Run Console:
  https://console.cloud.google.com/run?project=$($CONFIG.ProjectId)

GitHub Actions:
  https://github.com/$GitHubRepo/actions
==============================================
"@ -ForegroundColor White

    # Copy to clipboard option
    $copyToClipboard = Read-Host "`nCopy secrets to clipboard? (y/n)"
    if ($copyToClipboard -eq 'y' -or $copyToClipboard -eq 'Y') {
        $clipboardText = @"
GCP_PROJECT_ID=$($CONFIG.ProjectId)
GCP_SERVICE_ACCOUNT_EMAIL=$serviceAccountEmail
GCP_WORKLOAD_IDENTITY_PROVIDER=$workloadIdentityProvider
"@
        Set-Clipboard -Value $clipboardText
        Write-Success "Secrets copied to clipboard!"
    }

    if ($keyFile) {
        Write-Host "`n" -ForegroundColor Red
        Write-Host "REMINDER: Delete the local key file after adding to GitHub!" -ForegroundColor Red
        Write-Host "  Remove-Item $keyFile" -ForegroundColor Yellow
    }
}
catch {
    Write-Err $_.Exception.Message
    Write-Host "`nSetup failed. Please check the error above." -ForegroundColor Red
    exit 1
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
