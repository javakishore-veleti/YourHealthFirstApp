@echo off
REM ############################################################################
REM GCP Setup Script for GitHub Actions Cloud Run Deployment (Windows CMD)
REM 
REM This script creates all necessary GCP resources for deploying
REM BOTH Angular UI and Flask Back Office from a SINGLE GitHub repository:
REM
REM Repository Structure:
REM   YourHealthFirstApp/
REM   ├── angular_front_end/healthcare_plans_ui/   (Angular UI)
REM   └── python_flask_back_office/healthcare_plans_bo/  (Flask API)
REM
REM Prerequisites:
REM   - gcloud CLI installed and in PATH
REM   - git installed and in PATH
REM   - Run: gcloud auth login
REM   - Owner or Editor role on the GCP project
REM
REM Usage:
REM   setup-gcp-cloud-run.cmd
REM ############################################################################

setlocal EnableDelayedExpansion

REM ============================================================================
REM CONFIGURATION - UPDATE THESE VALUES
REM ============================================================================

set PROJECT_ID=engineering-college-apps
set REGION=us-central1
set SERVICE_ACCOUNT_NAME=yourhealthplans-github-actions-cloudrun
set POOL_NAME=github-actions-pool
set PROVIDER_NAME=github-actions-provider

REM Artifact Registry repositories (two repos for one GitHub repo)
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
    echo WARNING: Could not detect git remote URL.
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
echo ==============================================
echo.
echo This will configure GCP for deploying BOTH:
echo   * Angular UI (angular_front_end/healthcare_plans_ui)
echo   * Flask BO (python_flask_back_office/healthcare_plans_bo)
echo.
echo From a SINGLE GitHub repository.
echo.
echo Configuration:
echo   Project ID:        %PROJECT_ID%
echo   Region:            %REGION%
echo   Service Account:   %SERVICE_ACCOUNT_NAME%
echo   GitHub Repo:       %GITHUB_REPO% (auto-detected)
echo.
echo Artifact Registries:
echo   UI Images:         %UI_ARTIFACT_REPO%
echo   BO Images:         %BO_ARTIFACT_REPO%
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
    cloudresourcemanager.googleapis.com
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
        --description="Service account for deploying Healthcare Plans UI and BO to Cloud Run"
    echo SUCCESS: Service Account created
)
echo.

REM Step 4: Grant IAM roles
echo [Step 4/8] Granting IAM roles to Service Account...

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

REM Step 5: Create Artifact Registry repositories
echo [Step 5/8] Creating Artifact Registry repositories...

echo   Creating UI repository: %UI_ARTIFACT_REPO%
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

echo   Creating BO repository: %BO_ARTIFACT_REPO%
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

echo   Creating Workload Identity Pool...
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

echo   Creating Workload Identity Provider...
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

echo   Configuring service account impersonation...
call gcloud iam service-accounts add-iam-policy-binding %SERVICE_ACCOUNT_EMAIL% ^
    --role="roles/iam.workloadIdentityUser" ^
    --member="principalSet://iam.googleapis.com/projects/%PROJECT_NUMBER%/locations/global/workloadIdentityPools/%POOL_NAME%/attribute.repository/%GITHUB_REPO%" ^
    --quiet >nul 2>&1
echo SUCCESS: Workload Identity Federation configured
echo.

REM Step 7: Create Service Account Key
echo [Step 7/8] Create Service Account Key (JSON)
echo.
echo   You have two authentication options for GitHub Actions:
echo.
echo   Option 1: Workload Identity Federation (More Secure - Recommended)
echo             - No JSON key needed
echo             - Uses OIDC tokens
echo.
echo   Option 2: Service Account Key (JSON)
echo             - Download JSON key file
echo             - Store entire JSON in GitHub Secret: GCP_SA_KEY
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
    echo.
    echo   1. Open the file: !KEY_FILE!
    echo.
    echo   2. Copy the ENTIRE contents (including curly braces)
    echo.
    echo   3. Go to GitHub repository secrets:
    echo      https://github.com/%GITHUB_REPO%/settings/secrets/actions
    echo.
    echo   4. Click 'New repository secret'
    echo.
    echo   5. Name: GCP_SA_KEY
    echo      Value: Paste the entire JSON content
    echo.
    echo   6. Click 'Add secret'
    echo.
    echo ==================================================================
    echo SECURITY WARNINGS:
    echo ==================================================================
    echo   * DELETE the local JSON file after adding to GitHub Secrets!
    echo   * NEVER commit this file to your repository!
    echo   * Add '!KEY_FILE!' to your .gitignore file!
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
echo GitHub Secrets Configuration
echo ----------------------------------------------
echo Add these secrets at:
echo   https://github.com/%GITHUB_REPO%/settings/secrets/actions
echo.
echo OPTION 1: Workload Identity Federation (Recommended)
echo ----------------------------------------------
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
    echo ----------------------------------------------
    echo OPTION 2: Service Account Key (Alternative)
    echo ----------------------------------------------
    echo GCP_PROJECT_ID
    echo   %PROJECT_ID%
    echo.
    echo GCP_SA_KEY
    echo   ^<Entire contents of %KEY_FILE%^>
    echo.
)

echo ----------------------------------------------
echo Artifact Registry URLs:
echo   UI: %REGION%-docker.pkg.dev/%PROJECT_ID%/%UI_ARTIFACT_REPO%
echo   BO: %REGION%-docker.pkg.dev/%PROJECT_ID%/%BO_ARTIFACT_REPO%
echo.
echo Cloud Run Console:
echo   https://console.cloud.google.com/run?project=%PROJECT_ID%
echo.
echo GitHub Actions:
echo   https://github.com/%GITHUB_REPO%/actions
echo ==============================================

if /i "%CREATE_KEY%"=="y" (
    echo.
    echo REMINDER: Delete the local key file after adding to GitHub!
    echo   del %KEY_FILE%
)

endlocal
pause
