# YourHealthFirstApp

## Prerequisites
1. Google Cloud CLI https://docs.cloud.google.com/sdk/docs/install-sdk
2. DockerHub https://hub.docker.com/welcome
3. nodejs https://nodejs.org/en/download
4. Python https://www.python.org/downloads/

## Branch 01 - Initial Folders and Angular Initialization Setup

### Branch Name: 01-Branch-Initial-Folders-Angular-SetUp
### Branch Purpose: Initial Folders and Angular Initialization Setup

```shell

git clone https://github.com/javakishore-veleti/YourHealthFirstApp

cd YourHealthFirstApp

##### STEP 01 START - Create folders for Python Flask and also Angular UI code #####

### Macbook USERS ONLY COMMANDS START
mkdir -p python_flask_back_office
mkdir -p angular_front_end

mkdir -p .github
mkdir -p .github/workflows
### Macbook USERS ONLY COMMANDS END

### WINDOWS USERS ONLY COMMANDS START
if not exist python_flask_back_office mkdir python_flask_back_office
if not exist angular_front_end        mkdir angular_front_end

if not exist .github                  mkdir .github
if not exist .github/workflows        mkdir .github/workflows
### WINDOWS USERS ONLY COMMANDS END

##### STEP 01 END #####

##### STEP 02 START - Initiate Angular Project Code #####

cd angular_front_end

ng new healthcare_plans_ui --routing --style=scss --ssr=false

# ? Do you want to create a 'zoneless' application without zone.js (Developer Preview)? (y/N) N
# ✔ Packages installed successfully.

cd healthcare_plans_ui

npm install bootstrap

npm start

### Open your browser and access http://localhost:4200/

##### STEP 02 END - Initiate Angular Project Code #####

```

## Branch 02 - Python Flask Back Office Initialization Setup

### Branch Name: 02-Branch-Python-Flask-Back-Office-SetUp
### Branch Purpose: Initial SetUp for Python Flask Back Office

```shell

cd python_flask_back_office

### Macbook USERS ONLY COMMANDS START
mkdir -p healthcare_plans_bo
cd healthcare_plans_bo
touch requirements.txt
touch main.py
touch __init__.py
touch config.py
touch extensions.py
touch run.py
### Macbook USERS ONLY COMMANDS END

### WINDOWS USERS ONLY COMMANDS START
if not exist healthcare_plans_bo mkdir healthcare_plans_bo
cd healthcare_plans_bo
if not exist requirements.txt type nul > requirements.txt
if not exist main.py type nul > main.py
if not exist __init__.py type nul > __init__.py
if not exist config.py type nul > config.py
if not exist extensions.py type nul > extensions.py
if not exist run.py type nul > run.py
### WINDOWS USERS ONLY COMMANDS END

### Macbook USERS ONLY COMMANDS START
cat << 'EOF' >> requirements.txt
# Flask Framework
Flask==3.0.0
Flask-RESTful==0.3.10

# SQLAlchemy ORM
Flask-SQLAlchemy==3.1.1
Flask-Migrate==4.0.5

# CORS
Flask-CORS==4.0.0

# JWT Authentication
Flask-JWT-Extended==4.6.0

# Database
# SQLite - built into Python, no package needed
# PostgreSQL (optional for production)
psycopg2-binary==2.9.10

# Production Server
gunicorn==21.2.0

# Environment variables
python-dotenv==1.0.1

# Utilities
python-dateutil==2.9.0
EOF

### Macbook USERS ONLY COMMANDS END


### WINDOWS USERS ONLY COMMANDS START
(
echo # Flask Framework
echo Flask==3.0.0
echo Flask-RESTful==0.3.10
echo.
echo # SQLAlchemy ORM
echo Flask-SQLAlchemy==3.1.1
echo Flask-Migrate==4.0.5
echo.
echo # CORS
echo Flask-CORS==4.0.0
echo.
echo # JWT Authentication
echo Flask-JWT-Extended==4.6.0
echo.
echo # Database
echo # SQLite - built into Python, no package needed
echo # PostgreSQL (optional for production)
echo psycopg2-binary==2.9.10
echo.
echo # Production Server
echo gunicorn==21.2.0
echo.
echo # Environment variables
echo python-dotenv==1.0.1
echo.
echo # Utilities
echo python-dateutil==2.9.0
) >> requirements.txt

### WINDOWS USERS ONLY COMMANDS END

```

### config.py file contents

```text

"""
Flask Application Configuration
"""
import os
from datetime import timedelta


class Config:
    """Base configuration"""
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'jwt-secret-key-change-in-production')
    
    # JWT Configuration
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    
    # Database - SQLite by default
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'sqlite:///healthcare_plans.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True


class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False


config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}

```


### extensions.py file contents

```text

"""
Flask Extensions
"""
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()
cors = CORS()

```

### main.py file contents

```text
"""
Flask Application Factory
"""
import os
from flask import Flask, jsonify
from config import config
from flask_back_office.extensions import db, migrate, jwt, cors


def create_app(config_name=None):
    """Create and configure Flask application"""
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'development')
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    cors.init_app(app, resources={r"/api/*": {"origins": "*"}})
    
    # Register blueprints
    from flask_back_office.accounts.api.views import accounts_bp
    from flask_back_office.catalog.api.views import catalog_bp
    from flask_back_office.cart.api.views import cart_bp
    
    app.register_blueprint(accounts_bp, url_prefix='/api/v1/accounts')
    app.register_blueprint(catalog_bp, url_prefix='/api/v1/catalog')
    app.register_blueprint(cart_bp, url_prefix='/api/v1/cart')
    
    # Root endpoint
    @app.route('/')
    def index():
        return jsonify({
            'message': 'Welcome to HealthCare Plans API (Flask)',
            'version': '1.0.0',
            'endpoints': {
                'accounts': '/api/v1/accounts/',
                'catalog': '/api/v1/catalog/',
                'cart': '/api/v1/cart/'
            }
        })
    
    # Health check
    @app.route('/api/v1/health/')
    def health():
        return jsonify({'status': 'healthy'})
    
    # Create tables
    with app.app_context():
        db.create_all()
    
    return app

```

### run.py file contents

```text

from main import create_app

app = create_app()

if __name__ == "__main__":
    app.run(debug=True)


```

### pip install

```shell
pip install -r requirements.txt
```

### Run the Flask App For The First Time

```shell
python run.py

### Open your browser and access http://127.0.0.1:5000/

```


## Branch 03 - Create Dockerfile(s) for Angular and Flask code

### Branch Name: 03-Branch-Dockerfiles-Flask-Angular-Apps
### Branch Purpose: Create Docker files for both Flask App and Angular App


### Angular Dockerifle contents
```text

# Stage 1: Build the Angular application
FROM node:20-alpine AS build

# Set working directory
WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./

# Install dependencies
RUN npm ci --legacy-peer-deps

# Copy the rest of the application source code
COPY . .

# Build the Angular app for production
# Adjust the project name if different in angular.json
RUN npm run build -- --configuration=production

# Stage 2: Serve the application with Nginx
FROM nginx:alpine AS production

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy custom nginx configuration for Cloud Run
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built Angular app from build stage
# Adjust the path based on your angular.json outputPath
# Common patterns: dist/healthcare_plans_ui, dist/healthcare-plans-ui, or dist/browser
COPY --from=build /app/dist/healthcare_plans_ui/browser /usr/share/nginx/html

# Cloud Run requires the container to listen on port 8080
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]


```

# Deploying to Google Cloud Run

This guide walks you through deploying the YourHealthFirstApp to Google Cloud Run using GitHub Actions.

## Prerequisites

Before deploying, ensure you have completed the following:

- [ ] GCP Project created and configured
- [ ] Run the `setup-gcp-cloudrun.sh` script (or `.cmd`/`.ps1` for Windows)
- [ ] GitHub Secrets configured (see [GitHub Secrets Setup](#github-secrets-setup))
- [ ] Dockerfiles in place for both Angular UI and Flask BO

---

## GitHub Secrets Setup

Add the following secrets to your GitHub repository:

1. Go to: **Repository → Settings → Secrets and variables → Actions**
2. Click **"New repository secret"** and add:

| Secret Name | Description |
|-------------|-------------|
| `GCP_PROJECT_ID` | Your GCP Project ID (e.g., `engineering-college-apps`) |
| `GCP_SERVICE_ACCOUNT_EMAIL` | Service account email from setup script |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity Provider from setup script |
| `GCP_SA_KEY` | *(Alternative)* Full JSON content of service account key |

---

## Deployment Order

> **Important:** Always deploy the backend API first, then the frontend UI.

### Why This Order?

1. **Backend First** - The Angular UI depends on the Flask API for data
2. **API Availability** - If the API isn't running, the UI may fail or show errors during initialization
3. **URL Configuration** - After deploying Flask, you'll get an API URL that may need to be configured in the Angular app

---

## Step 1: Deploy Flask Back Office (API)

The Flask Back Office provides the REST API endpoints for the application.

### 1.1 Navigate to GitHub Actions

Go to: [https://github.com/javakishore-veleti/YourHealthFirstApp/actions](https://github.com/javakishore-veleti/YourHealthFirstApp/actions)

### 1.2 Select the Deploy Workflow

1. In the left sidebar, click **"GCP Healthcare BO - Deploy"**
2. Click the **"Run workflow"** dropdown button (on the right side)

### 1.3 Configure Deployment Options

Select the following options:

| Option | Value | Description |
|--------|-------|-------------|
| **Environment** | `dev` | Target environment (dev/staging/prod) |
| **Region** | `us-central1` | GCP region for deployment |

### 1.4 Start Deployment

Click the green **"Run workflow"** button.

### 1.5 Monitor Progress

- The workflow will appear in the list with a yellow dot (in progress)
- Click on the workflow run to see detailed logs
- Wait for all steps to complete (green checkmark)

### 1.6 Get the API URL

After successful deployment, you'll find the **Service URL** in the workflow summary:

```
https://healthcare-plans-bo-dev-xxxxxxxxxx-uc.a.run.app
```

> **📝 Note:** Save this URL! You may need it to configure the Angular UI's API endpoint.

### 1.7 Verify the API

Test the API is running by visiting:

```
https://healthcare-plans-bo-dev-xxxxxxxxxx-uc.a.run.app/api/v1/health/
```

You should see a health check response.

---

## Step 2: Deploy Angular UI (Frontend)

The Angular UI provides the web interface for users.

### 2.1 Navigate to GitHub Actions

Go to: [https://github.com/javakishore-veleti/YourHealthFirstApp/actions](https://github.com/javakishore-veleti/YourHealthFirstApp/actions)

### 2.2 Select the Deploy Workflow

1. In the left sidebar, click **"GCP Healthcare UI - Deploy"**
2. Click the **"Run workflow"** dropdown button

### 2.3 Configure Deployment Options

Select the following options:

| Option | Value | Description |
|--------|-------|-------------|
| **Environment** | `dev` | Target environment (must match API environment) |
| **Region** | `us-central1` | GCP region (should match API region) |

### 2.4 Start Deployment

Click the green **"Run workflow"** button.

### 2.5 Monitor Progress

- Watch the workflow progress in the Actions tab
- Wait for all steps to complete successfully

### 2.6 Get the UI URL

After successful deployment, you'll find the **Service URL** in the workflow summary:

```
https://healthcare-plans-ui-dev-xxxxxxxxxx-uc.a.run.app
```

### 2.7 Verify the Application

Open the UI URL in your browser to verify the application is running correctly.

---

## Deployment Summary

After completing both deployments, you'll have:

| Service | URL Pattern | Purpose |
|---------|-------------|---------|
| **Flask API** | `https://healthcare-plans-bo-dev-xxx.a.run.app` | Backend REST API |
| **Angular UI** | `https://healthcare-plans-ui-dev-xxx.a.run.app` | Frontend Web Application |

---

## Other Workflow Actions

Besides deployment, you have additional workflows available:

| Workflow | Purpose |
|----------|---------|
| **Stop** | Scale service to 0 instances (pause without deleting) |
| **Restart** | Restart service with new instances |
| **Health Check** | Verify service health and get status |
| **Status** | View all deployed services and their status |
| **Destroy** | Permanently delete the service (⚠️ destructive) |

---

## Deploying to Different Environments

To deploy to staging or production:

1. Run the deploy workflow
2. Select the appropriate environment:
   - `dev` - Development/testing
   - `staging` - Pre-production testing
   - `prod` - Production

> **⚠️ Production Deployments:** Always test in `dev` and `staging` before deploying to `prod`.

---

## Troubleshooting

### Common Issues

**1. Workflow fails at authentication step**
- Verify GitHub Secrets are correctly configured
- Check that the service account has the required IAM roles

**2. Docker build fails**
- Ensure Dockerfile exists in the correct location
- Check that all required files (nginx.conf, requirements.txt) are present

**3. Service URL returns 404 or error**
- Check the workflow logs for deployment errors
- Verify the health check endpoint is working
- Review Cloud Run logs in GCP Console

### Viewing Logs

To view detailed logs:
1. Go to [GCP Cloud Run Console](https://console.cloud.google.com/run)
2. Select your service
3. Click on "Logs" tab

---

## Quick Reference

### Deploy Commands (via GitHub Actions UI)

```
1. Flask API:  Actions → "GCP Healthcare BO - Deploy" → Run workflow
2. Angular UI: Actions → "GCP Healthcare UI - Deploy" → Run workflow
```

### Useful Links

- **GitHub Actions:** [Repository Actions Tab](https://github.com/javakishore-veleti/YourHealthFirstApp/actions)
- **GCP Cloud Run Console:** [Cloud Run Dashboard](https://console.cloud.google.com/run)
- **GCP Artifact Registry:** [Container Images](https://console.cloud.google.com/artifacts)

---

## Next Steps After Deployment

1. **Configure API URL in Angular** - Update environment files if needed
2. **Set up Custom Domain** - Configure custom domain in Cloud Run settings
3. **Enable CI/CD** - Modify workflows to trigger on push to specific branches
4. **Set up Monitoring** - Configure Cloud Monitoring alerts
