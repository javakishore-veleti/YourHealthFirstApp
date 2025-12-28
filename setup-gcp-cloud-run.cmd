@echo off
REM ############################################################################
REM GCP Setup Script for GitHub Actions Cloud Run Deployment (Windows CMD)
REM 
REM This script creates all necessary GCP resources:
REM 1. Service Account with required permissions
REM 2. Artifact Registry repository for Docker images
REM 3. Workload Identity Federation for secure GitHub authentication
REM
REM Prerequisites:
REM   - gcloud CLI installed and in PATH
REM   - git installed and in PATH
REM   - Run: gcloud auth login
REM   - Owner or Editor role on the GCP project
REM   - Run this script from within a git repository
REM
REM Usage:
REM   gcp-healthcare-cloud-run-setup.cmd
REM ############################################################################

setlocal EnableDelayedExpansion

REM ============================================================================
REM CONFIGURATION - UPDATE THESE VALUES
REM ============================================================================

set PROJECT_ID=engineering-college-apps
set REGION=us-central1
set SERVICE_ACCOUNT_NAME=github-actions-cloudrun
set POOL_NAME=github-actions-pool
set PROVIDER_NAME=github-actions-provider

REM Artifact Registry repositories
set UI_ARTIFACT_REPO=healthcare-plans-ui
set BO_ARTIFACT_REPO=healthcare-plans-bo

REM ============================================================================
REM AUTO-DETECT GITHUB REPOSITORY
REM ============================================================================

echo Detecting GitHub repository...

REM Check if we're in a git repository
git rev-parse --is-inside-work-tree >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Not in a git repository.
    set /p GITHUB_REPO="Enter GitHub repository (format: owner/repo): "
    goto :check_repo
)

REM Get the remote URL
for /f "tokens=*" %%i in ('git remote get-url origin 2^>nul') do set REMOTE_URL=%%i

if "%REMOTE_URL%"=="" (
    for /f "tokens=*" %%i in ('git remote 2^>nul') do (
        for /f "tokens=*" %%j in ('git remote get-url %%i 2^>nul') do set REMOTE_URL=%%j
        goto :parse_url
    )
)

:parse_url
if "%REMOTE_URL%"=="" (
    echo WARNING: Could not detect git remote URL.
    set /p GITHUB_REPO="Enter GitHub repository (format: owner/repo): "
    goto :check_repo
)

REM Parse GitHub repo from URL
REM Handle: https://github.com/owner/repo.git or git@github.com:owner/repo.git

REM Remove .git suffix if present
set REMOTE_URL=%REMOTE_URL:.git=%

REM Handle HTTPS URL: https://github.com/owner/repo
echo %REMOTE_URL% | findstr /C:"https://github.com/" >nul
if %ERRORLEVEL% EQU 0 (
    set GITHUB_REPO=%REMOTE_URL:https://github.com/=%
    goto :check_repo
)

REM Handle SSH URL: git@github.com:owner/repo
echo %REMOTE_URL% | findstr /C:"git@github.com:" >nul
if %ERRORLEVEL% EQU 0 (
    set GITHUB_REPO=%REMOTE_URL:git@github.com:=%
    goto :check_repo
)

REM Could not parse
echo WARNING: Could not parse GitHub URL from: %REMOTE_URL%
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
echo   Healthcare Plans Application
echo ==============================================
echo.
echo Configuration:
echo   Project ID:   %PROJECT_ID%
echo   Region:       %REGION%
echo   GitHub Repo:  %GITHUB_REPO% (auto-detected)
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul
echo.

REM Set the project
echo [Step 1/7] Setting GCP project...
call gcloud config set project %PROJECT_ID%
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to set project. Make sure you're logged in with: gcloud auth login
    exit /b 1
)
echo SUCCESS: Project set
echo.

REM Enable required APIs
echo [Step 2/7] Enabling required GCP APIs...
call gcloud services enable ^
    cloudbuild.googleapis.com ^
    run.googleapis.com ^
    artifactregistry.googleapis.com ^
    iamcredentials.googleapis.com ^
    iam.googleapis.com ^
    cloudresourcemanager.googleapis.com
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to enable APIs
    exit /b 1
)
echo SUCCESS: APIs enabled
echo.

REM Create Service Account
echo [Step 3/7] Creating Service Account...
set SERVICE_ACCOUNT_EMAIL=%SERVICE_ACCOUNT_NAME%@%PROJECT_ID%.iam.gserviceaccount.com

call gcloud iam service-accounts describe %SERVICE_ACCOUNT_EMAIL% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo WARNING: Service Account already exists, skipping creation
) else (
    call gcloud iam service-accounts create %SERVICE_ACCOUNT_NAME% ^
        --display-name="GitHub Actions Cloud Run Deployer" ^
        --description="Service account for deploying Healthcare Plans to Cloud Run"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to create service account
        exit /b 1
    )
    echo SUCCESS: Service Account created
)
echo.

REM Grant IAM roles
echo [Step 4/7] Granting IAM roles to Service Account...

set ROLES=roles/run.admin roles/artifactregistry.writer roles/artifactregistry.reader roles/iam.serviceAccountUser roles/storage.admin

for %%R in (%ROLES%) do (
    echo   Adding %%R...
    call gcloud projects add-iam-policy-binding %PROJECT_ID% ^
        --member="serviceAccount:%SERVICE_ACCOUNT_EMAIL%" ^
        --role="%%R" ^
        --quiet >nul 2>&1
)
echo SUCCESS: IAM roles granted
echo.

REM Create Artifact Registry repositories
echo [Step 5/7] Creating Artifact Registry repositories...

REM UI Repository
call gcloud artifacts repositories describe %UI_ARTIFACT_REPO% --location=%REGION% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo WARNING: Repository %UI_ARTIFACT_REPO% already exists, skipping
) else (
    call gcloud artifacts repositories create %UI_ARTIFACT_REPO% ^
        --repository-format=docker ^
        --location=%REGION% ^
        --description="Docker images for Healthcare Plans Angular UI"
    echo SUCCESS: Repository %UI_ARTIFACT_REPO% created
)

REM BO Repository
call gcloud artifacts repositories describe %BO_ARTIFACT_REPO% --location=%REGION% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo WARNING: Repository %BO_ARTIFACT_REPO% already exists, skipping
) else (
    call gcloud artifacts repositories create %BO_ARTIFACT_REPO% ^
        --repository-format=docker ^
        --location=%REGION% ^
        --description="Docker images for Healthcare Plans Flask Back Office"
    echo SUCCESS: Repository %BO_ARTIFACT_REPO% created
)
echo.

REM Setup Workload Identity Federation
echo [Step 6/7] Setting up Workload Identity Federation...

REM Create Workload Identity Pool
echo   Creating Workload Identity Pool...
call gcloud iam workload-identity-pools describe %POOL_NAME% --location="global" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   WARNING: Workload Identity Pool already exists, skipping
) else (
    call gcloud iam workload-identity-pools create %POOL_NAME% ^
        --location="global" ^
        --display-name="GitHub Actions Pool" ^
        --description="Identity pool for GitHub Actions CI/CD"
    echo   SUCCESS: Workload Identity Pool created
)

REM Create Workload Identity Provider
echo   Creating Workload Identity Provider...
call gcloud iam workload-identity-pools providers describe %PROVIDER_NAME% ^
    --workload-identity-pool=%POOL_NAME% ^
    --location="global" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   WARNING: Workload Identity Provider already exists, skipping
) else (
    call gcloud iam workload-identity-pools providers create-oidc %PROVIDER_NAME% ^
        --location="global" ^
        --workload-identity-pool=%POOL_NAME% ^
        --display-name="GitHub Actions Provider" ^
        --issuer-uri="https://token.actions.githubusercontent.com" ^
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" ^
        --attribute-condition="assertion.repository=='%GITHUB_REPO%'"
    echo   SUCCESS: Workload Identity Provider created
)

REM Get Workload Identity Provider full name
echo   Getting Workload Identity Provider resource name...
for /f "tokens=*" %%i in ('gcloud iam workload-identity-pools providers describe %PROVIDER_NAME% --workload-identity-pool=%POOL_NAME% --location="global" --format="value(name)"') do set WORKLOAD_IDENTITY_PROVIDER=%%i

REM Get Project Number
for /f "tokens=*" %%i in ('gcloud projects describe %PROJECT_ID% --format="value(projectNumber)"') do set PROJECT_NUMBER=%%i

REM Configure service account impersonation
echo   Configuring service account impersonation...
call gcloud iam service-accounts add-iam-policy-binding %SERVICE_ACCOUNT_EMAIL% ^
    --role="roles/iam.workloadIdentityUser" ^
    --member="principalSet://iam.googleapis.com/projects/%PROJECT_NUMBER%/locations/global/workloadIdentityPools/%POOL_NAME%/attribute.repository/%GITHUB_REPO%" ^
    --quiet >nul 2>&1
echo SUCCESS: Workload Identity Federation configured
echo.

REM Optional: Create Service Account Key
echo [Step 7/7] Service Account Key (Optional)
set /p CREATE_KEY="Do you want to create a Service Account Key? (y/n): "
if /i "%CREATE_KEY%"=="y" (
    set KEY_FILE=gcp-healthcare-sa-key.json
    call gcloud iam service-accounts keys create !KEY_FILE! ^
        --iam-account=%SERVICE_ACCOUNT_EMAIL%
    echo SUCCESS: Service Account Key saved to: !KEY_FILE!
    echo.
    echo WARNING: Keep this key secure and delete after adding to GitHub Secrets!
)

REM ============================================================================
REM OUTPUT SUMMARY
REM ============================================================================

echo.
echo ==============================================
echo   SETUP COMPLETE!
echo ==============================================
echo.
echo GitHub Secrets Configuration
echo ----------------------------------------------
echo Add these secrets to your GitHub repository:
echo   https://github.com/%GITHUB_REPO%/settings/secrets/actions
echo.
echo SECRET NAME                        VALUE
echo ----------------------------------------------
echo GCP_PROJECT_ID                     %PROJECT_ID%
echo GCP_SERVICE_ACCOUNT_EMAIL          %SERVICE_ACCOUNT_EMAIL%
echo.
echo GCP_WORKLOAD_IDENTITY_PROVIDER:
echo %WORKLOAD_IDENTITY_PROVIDER%
echo.
if /i "%CREATE_KEY%"=="y" (
    echo Alternative - Service Account Key:
    echo GCP_SA_KEY                         Contents of %KEY_FILE%
    echo.
)
echo ----------------------------------------------
echo Artifact Registry URLs:
echo   UI:  %REGION%-docker.pkg.dev/%PROJECT_ID%/%UI_ARTIFACT_REPO%
echo   BO:  %REGION%-docker.pkg.dev/%PROJECT_ID%/%BO_ARTIFACT_REPO%
echo.
echo Cloud Run Console:
echo   https://console.cloud.google.com/run?project=%PROJECT_ID%
echo.
echo GitHub Actions:
echo   https://github.com/%GITHUB_REPO%/actions
echo ==============================================

endlocal
pause
