@echo off
REM ############################################################################
REM GCP Setup Script for GitHub Actions Cloud Run Deployment (Windows CMD)
REM 
REM Comprehensive roles including Cloud SQL, Secret Manager, etc.
REM ############################################################################

setlocal EnableDelayedExpansion

REM ============================================================================
REM CONFIGURATION - UPDATE THESE VALUES
REM ============================================================================

set PROJECT_ID=engineering-college-apps
set REGION=us-central1
set SERVICE_ACCOUNT_NAME=yhp-github-cloudrun
set POOL_NAME=github-actions-pool
set PROVIDER_NAME=github-actions-provider

set UI_ARTIFACT_REPO=healthcare-plans-ui
set BO_ARTIFACT_REPO=healthcare-plans-bo

REM ============================================================================
REM AUTO-DETECT GITHUB REPOSITORY
REM ============================================================================

echo Detecting GitHub repository...

git rev-parse --is-inside-work-tree >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Not in a git repository.
    set /p GITHUB_REPO="Enter GitHub repository (format: owner/repo): "
    goto :check_repo
)

for /f "tokens=*" %%i in ('git remote get-url origin 2^>nul') do set REMOTE_URL=%%i

if "%REMOTE_URL%"=="" (
    set /p GITHUB_REPO="Enter GitHub repository (format: owner/repo): "
    goto :check_repo
)

set REMOTE_URL=%REMOTE_URL:.git=%

echo %REMOTE_URL% | findstr /C:"https://github.com/" >nul
if %ERRORLEVEL% EQU 0 (
    set GITHUB_REPO=%REMOTE_URL:https://github.com/=%
    goto :check_repo
)

echo %REMOTE_URL% | findstr /C:"git@github.com:" >nul
if %ERRORLEVEL% EQU 0 (
    set GITHUB_REPO=%REMOTE_URL:git@github.com:=%
    goto :check_repo
)

set /p GITHUB_REPO="Enter GitHub repository (format: owner/repo): "

:check_repo
if "%GITHUB_REPO%"=="" (
    echo ERROR: GitHub repository is required. Exiting.
    exit /b 1
)

REM ============================================================================
REM SCRIPT START
REM ============================================================================

echo.
echo ==============================================
echo   GCP Cloud Run Setup for GitHub Actions
echo   (With Comprehensive IAM Roles)
echo ==============================================
echo.
echo Configuration:
echo   Project ID:        %PROJECT_ID%
echo   Region:            %REGION%
echo   Service Account:   %SERVICE_ACCOUNT_NAME%
echo   GitHub Repo:       %GITHUB_REPO% (auto-detected)
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul
echo.

REM Step 1: Set Project
echo [Step 1/8] Setting GCP project...
call gcloud config set project %PROJECT_ID%
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to set project.
    exit /b 1
)
echo SUCCESS: Project set
echo.

REM Step 2: Enable APIs
echo [Step 2/8] Enabling required GCP APIs...
call gcloud services enable ^
    cloudbuild.googleapis.com ^
    run.googleapis.com ^
    artifactregistry.googleapis.com ^
    iamcredentials.googleapis.com ^
    iam.googleapis.com ^
    cloudresourcemanager.googleapis.com ^
    sqladmin.googleapis.com ^
    secretmanager.googleapis.com
echo SUCCESS: APIs enabled
echo.

REM Step 3: Create Service Account
echo [Step 3/8] Creating Service Account...
set SERVICE_ACCOUNT_EMAIL=%SERVICE_ACCOUNT_NAME%@%PROJECT_ID%.iam.gserviceaccount.com

call gcloud iam service-accounts describe %SERVICE_ACCOUNT_EMAIL% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo WARNING: Service Account already exists, skipping creation
) else (
    call gcloud iam service-accounts create %SERVICE_ACCOUNT_NAME% ^
        --display-name="YourHealthPlans GitHub Actions Cloud Run Deployer" ^
        --description="Service account for deploying Healthcare Plans to Cloud Run"
    echo SUCCESS: Service Account created
)
echo.

REM Step 4: Grant IAM roles (Comprehensive)
echo [Step 4/8] Granting IAM roles to Service Account...
echo.
echo   Assigning comprehensive roles for Cloud Run, Artifact Registry,
echo   Cloud SQL, Secret Manager, and Storage...
echo.

REM Comprehensive roles matching your working configuration
set ROLES=roles/artifactregistry.admin roles/artifactregistry.writer roles/run.admin roles/cloudsql.admin roles/cloudsql.client roles/secretmanager.admin roles/secretmanager.secretAccessor roles/iam.serviceAccountUser roles/storage.admin

for %%R in (%ROLES%) do (
    echo   Adding %%R...
    call gcloud projects add-iam-policy-binding %PROJECT_ID% ^
        --member="serviceAccount:%SERVICE_ACCOUNT_EMAIL%" ^
        --role="%%R" ^
        --quiet >nul 2>&1
)
echo.
echo SUCCESS: All IAM roles granted (9 roles)
echo.

REM Step 5: Create Artifact Registry repositories
echo [Step 5/8] Creating Artifact Registry repositories...

call gcloud artifacts repositories describe %UI_ARTIFACT_REPO% --location=%REGION% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   WARNING: Repository %UI_ARTIFACT_REPO% already exists
) else (
    call gcloud artifacts repositories create %UI_ARTIFACT_REPO% ^
        --repository-format=docker ^
        --location=%REGION% ^
        --description="Docker images for Healthcare Plans Angular UI"
    echo   SUCCESS: Repository %UI_ARTIFACT_REPO% created
)

call gcloud artifacts repositories describe %BO_ARTIFACT_REPO% --location=%REGION% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   WARNING: Repository %BO_ARTIFACT_REPO% already exists
) else (
    call gcloud artifacts repositories create %BO_ARTIFACT_REPO% ^
        --repository-format=docker ^
        --location=%REGION% ^
        --description="Docker images for Healthcare Plans Flask Back Office"
    echo   SUCCESS: Repository %BO_ARTIFACT_REPO% created
)
echo.

REM Step 6: Setup Workload Identity Federation
echo [Step 6/8] Setting up Workload Identity Federation...

call gcloud iam workload-identity-pools describe %POOL_NAME% --location="global" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   WARNING: Pool already exists, skipping
) else (
    call gcloud iam workload-identity-pools create %POOL_NAME% ^
        --location="global" ^
        --display-name="GitHub Actions Pool" ^
        --description="Identity pool for GitHub Actions CI/CD"
    echo   SUCCESS: Pool created
)

call gcloud iam workload-identity-pools providers describe %PROVIDER_NAME% ^
    --workload-identity-pool=%POOL_NAME% ^
    --location="global" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   WARNING: Provider already exists, skipping
) else (
    call gcloud iam workload-identity-pools providers create-oidc %PROVIDER_NAME% ^
        --location="global" ^
        --workload-identity-pool=%POOL_NAME% ^
        --display-name="GitHub Actions Provider" ^
        --issuer-uri="https://token.actions.githubusercontent.com" ^
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" ^
        --attribute-condition="assertion.repository=='%GITHUB_REPO%'"
    echo   SUCCESS: Provider created
)

for /f "tokens=*" %%i in ('gcloud iam workload-identity-pools providers describe %PROVIDER_NAME% --workload-identity-pool=%POOL_NAME% --location="global" --format="value(name)"') do set WORKLOAD_IDENTITY_PROVIDER=%%i
for /f "tokens=*" %%i in ('gcloud projects describe %PROJECT_ID% --format="value(projectNumber)"') do set PROJECT_NUMBER=%%i

call gcloud iam service-accounts add-iam-policy-binding %SERVICE_ACCOUNT_EMAIL% ^
    --role="roles/iam.workloadIdentityUser" ^
    --member="principalSet://iam.googleapis.com/projects/%PROJECT_NUMBER%/locations/global/workloadIdentityPools/%POOL_NAME%/attribute.repository/%GITHUB_REPO%" ^
    --quiet >nul 2>&1
echo SUCCESS: Workload Identity Federation configured
echo.

REM Step 7: Create Service Account Key
echo [Step 7/8] Create Service Account Key (JSON)
echo.
set /p CREATE_KEY="Do you want to create/download a Service Account Key JSON? (y/n): "

if /i "%CREATE_KEY%"=="y" (
    set KEY_FILE=%SERVICE_ACCOUNT_NAME%-key.json
    
    echo.
    echo Creating and downloading Service Account Key...
    call gcloud iam service-accounts keys create !KEY_FILE! ^
        --iam-account=%SERVICE_ACCOUNT_EMAIL%
    
    echo.
    echo SUCCESS: Service Account Key saved to: !KEY_FILE!
    echo.
    echo ==================================================================
    echo HOW TO ADD JSON KEY TO GITHUB SECRETS:
    echo ==================================================================
    echo   1. Open: !KEY_FILE!
    echo   2. Copy ENTIRE contents
    echo   3. Go to: https://github.com/%GITHUB_REPO%/settings/secrets/actions
    echo   4. New secret: GCP_SA_KEY = paste JSON
    echo   5. DELETE local file after!
    echo ==================================================================
)
echo.

REM Step 8: Summary
echo [Step 8/8] Setup Complete!
echo.
echo ==============================================
echo   SETUP COMPLETE!
echo ==============================================
echo.
echo Service Account Roles Assigned:
echo   * Artifact Registry Administrator
echo   * Artifact Registry Writer
echo   * Cloud Run Admin
echo   * Cloud SQL Admin
echo   * Cloud SQL Client
echo   * Secret Manager Admin
echo   * Secret Manager Secret Accessor
echo   * Service Account User
echo   * Storage Admin
echo.
echo GitHub Secrets (add at):
echo   https://github.com/%GITHUB_REPO%/settings/secrets/actions
echo.
echo GCP_PROJECT_ID
echo   %PROJECT_ID%
echo.
echo GCP_SERVICE_ACCOUNT_EMAIL
echo   %SERVICE_ACCOUNT_EMAIL%
echo.
echo GCP_WORKLOAD_IDENTITY_PROVIDER
echo   %WORKLOAD_IDENTITY_PROVIDER%
echo.

if /i "%CREATE_KEY%"=="y" (
    echo OR use Service Account Key:
    echo GCP_SA_KEY = contents of %KEY_FILE%
    echo.
    echo REMINDER: Delete %KEY_FILE% after adding to GitHub!
)

echo ==============================================

endlocal
pause
