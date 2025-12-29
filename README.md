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

# Password Hashing (included with Werkzeug, but explicit)
Werkzeug>=3.0.0

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

## "Your Health Plans" - Healthcare Insurance Plans Purchasing Website

A full-stack web application that enables customers to search, compare, and purchase healthcare insurance plans online with a seamless shopping cart experience.

**Tech Stack:** Python + Django REST Framework | Angular 17 + Bootstrap 5 | PostgreSQL/MySQL | Google Cloud Platform

---

## Table of Contents

1. [Business Scenario](#part-1-business-scenario)
2. [System Architecture Overview](#part-2-system-architecture-overview)
3. [Requirements Analysis](#part-3-requirements-analysis)
4. [Django Apps Structure](#part-4-django-apps-structure)
5. [J2EE-Style Layered Architecture](#part-5-j2ee-style-layered-architecture)
6. [Technology Stack](#part-6-technology-stack)
7. [Entity Relationship Diagram](#part-7-entity-relationship-diagram)
8. [API Endpoints Design](#part-8-api-endpoints-design)
9. [Solution Architecture](#part-9-solution-architecture)
10. [Chatbot & Workflow Architecture (Phase 2)](#part-10-chatbot--workflow-architecture-phase-2)
11. [Getting Started](#part-11-getting-started)

---

## Part 1: Business Scenario

### 1.1 CEO's Strategic Vision

**From:** Rajesh Kumar, CEO - YourHealthFirst Insurance Ltd (a fictitious company)  
**To:** Executive Leadership Team  
**Subject:** Strategic Initiative Q1 2026 - Digital Transformation

---

*"Team,*

*As we enter 2026, our healthcare insurance market is rapidly growing. Customers expect better website, and our competitors are already providing better healthcare plan purchasing experiences. To maintain our market leadership and  grow our business, I am announcing our top and immediate business priorities:*

**Strategic Objectives:**

1. **Growth** - Expand our customers by 40% through digital channels (web, mobile, partners, airport kiosks, and other marketplaces)

2. **Customer Experience** - Provide 24/7 self-service for healthcare plan discovery and purchase

3. **Operational Efficiency** - Reduce manual processing by automating customer signup and plan purchasing processes

4. **Innovation** - Use AI/ML for customers personalized plan recommendations

**Investment:** *I have secured board approval for a ₹100 Crores (approx. $10 million) budget for this digital initiative.*

**Timeline:** *We need the first phase live within 2 months to capture the upcoming New Year season.*

*I am asking our Business Leaders and Enterprise Architecture team to collaborate and define the product scope. Let's make this happen!*

*- Rajesh Kumar, CEO"*

---

### 1.2 Business & Enterprise Architect Collaboration

**Meeting Notes: Product Definition Workshop**  
**Attendees:** Priya Sharma (VP Business), Venkat Rao (Enterprise Architect), Anita Reddy (Product Owner)

---

**Product Name:** **"Your Health Plans"**

**Product Vision:**  
A customer-facing website that allows individuals and families to search, compare, and purchase healthcare insurance plans online with a shopping cart experience.

**Target Users:**

| User Type | Description |
|-----------|-------------|
| **Customer** | Individuals/families looking to buy health insurance plans |
| **Admin** |  "Your Health Plans" staff managing plans, orders, and customer queries |
| **System** | Automated workflows for payment processing and notifications |

**Core Capabilities Identified:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    "YOUR HEALTH PLANS" PLATFORM                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  👤 CUSTOMER JOURNEY                                            │
│  ─────────────────────────────────────────────────────────────  │
│  [Browse Plans] → [Compare] → [Add to Cart] → [Checkout] → [Pay]│
│                                                                 │
│  🔐 ACCOUNT MANAGEMENT                                          │
│  ─────────────────────────────────────────────────────────────  │
│  [Sign Up] → [Login] → [View Profile] → [Order History]         │
│                                                                 │
│  🤖 AI ASSISTANT (Phase 2)                                      │
│  ─────────────────────────────────────────────────────────────  │
│  [Chat] → [Plan Recommendations] → [FAQ Answers]                │
│                                                                 │
│  🔧 ADMIN OPERATIONS                                            │
│  ─────────────────────────────────────────────────────────────  │
│  [Manage Plans] → [View Orders] → [Process Enrollments]         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Phase 1 Scope (2 Months - ₹40 Cr):**
- Customer signup/login
- Plan catalog browsing
- Shopping cart
- Basic checkout with payment gateway
- Admin plan management

**Phase 2 Scope (Future):**
- AI Chatbot for plan recommendations
- Workflow automation for enrollment processing
- Family plan management
- Document upload for KYC

---

### 1.3 Business Requirements Document (BRD)

**Prepared by:** Anita Reddy, Product Owner  
**Version:** 1.0

---

#### Business Requirements - "Your Health Plans" Platform

**Paragraph 1: Customer Experience Requirements**

The platform shall enable customers to create an account using their email and mobile number, with secure password-based authentication. Once logged in, customers shall be able to browse the complete catalog of healthcare plans offered by HealthFirst, including Individual Plans, Family Floater Plans, and Senior Citizen Plans. Each plan listing shall display the plan name, coverage amount, premium (monthly/annual), key benefits, and waiting periods. Customers shall be able to add one or more plans to their shopping cart, review the cart contents, modify quantities or remove items, and proceed to checkout. The checkout process shall collect the customer's personal details and redirect to a secure payment gateway for processing. Upon successful payment, the system shall generate an order confirmation and send a confirmation email to the customer. Customers shall be able to view their order history and download policy documents from their account dashboard.

**Paragraph 2: Admin and System Requirements**

The platform shall provide an administrative interface for HealthFirst staff to manage the healthcare plan catalog, including the ability to add new plans, update pricing and benefits, activate or deactivate plans, and organize plans by category. Administrators shall have access to view all customer orders, update order status (processing, approved, policy issued), and handle cancellation requests. The system shall integrate with a payment gateway to process premium payments securely, with support for credit/debit cards and UPI. For Phase 2, the platform shall include an AI-powered chatbot that can answer frequently asked questions about plans, help customers compare plans based on their requirements (age, family size, budget), and guide them through the purchase process. The chatbot shall be built using workflow automation tools available on Google Cloud Platform to orchestrate conversations and integrate with the plan recommendation engine.

---

## Part 2: System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                         USERS                                            │
├───────────────────────────────────────────┬─────────────────────────────────────────────┤
│              👤 CUSTOMERS                  │              👨‍💼 ADMINS                       │
│     (Individuals & Families)              │        (HealthFirst Staff)                  │
└─────────────────────┬─────────────────────┴─────────────────────┬───────────────────────┘
                      │                                           │
                      ▼                                           ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                            FRONTEND LAYER (Angular 17 + Bootstrap 5)                     │
├───────────────────────────────────────────┬─────────────────────────────────────────────┤
│       📱 CUSTOMER PORTAL                   │         🖥️ ADMIN PORTAL                      │
│       "yourhealthplans.com"               │         "admin.yourhealthplans.com"         │
│       ───────────────────────             │         ───────────────────────             │
│       • Plan Catalog & Search             │         • Plan Management (CRUD)            │
│       • Plan Comparison                   │         • Order Management                  │
│       • Shopping Cart                     │         • Customer Management               │
│       • Checkout & Payment                │         • Reports & Dashboard               │
│       • Order History                     │         • Chatbot Training                  │
│       • Profile Management                │                                             │
│       ───────────────────────             │         ───────────────────────             │
│       🤖 AI Chat Widget (Phase 2)         │         Deployed: Cloud Run / Firebase      │
│       Deployed: Cloud Run / Firebase      │                                             │
└─────────────────────┬─────────────────────┴─────────────────────┬───────────────────────┘
                      │                                           │
                      │            HTTPS / REST API               │
                      └─────────────────────┬─────────────────────┘
                                            ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              GCP LOAD BALANCER (Cloud Load Balancing)                    │
└─────────────────────────────────────────────┬───────────────────────────────────────────┘
                                              │
          ┌───────────────┬───────────────────┼───────────────────┬───────────────────┐
          ▼               ▼                   ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                    BACKEND MICROSERVICES (Django REST Framework)                         │
│                                  Deployed on Cloud Run                                   │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────────┬───────────────────┤
│  ACCOUNTS   │   CATALOG   │    CART     │   ORDERS    │  PAYMENTS   │    CHATBOT        │
│  SERVICE    │   SERVICE   │   SERVICE   │   SERVICE   │   SERVICE   │    SERVICE        │
│  ─────────  │  ─────────  │  ─────────  │  ─────────  │  ─────────  │   (Phase 2)       │
│  • Signup   │  • Plans    │  • Add      │  • Create   │  • Initiate │  ─────────        │
│  • Login    │  • Category │  • Update   │  • List     │  • Verify   │  • Dialogflow     │
│  • Profile  │  • Search   │  • Remove   │  • Status   │  • Webhook  │  • Intents        │
│  • JWT      │  • CRUD     │  • Clear    │  • History  │  • Refund   │  • Fulfillment    │
├─────────────┴─────────────┴─────────────┴─────────────┴─────────────┴───────────────────┤
│                              J2EE-STYLE LAYERED ARCHITECTURE                             │
│         ┌────────────┐      ┌────────────┐      ┌────────────┐      ┌────────────┐      │
│         │ API Layer  │  →   │  Service   │  →   │ DAO Layer  │  →   │   Models   │      │
│         │ (views.py) │      │  Layer     │      │ (dao.py)   │      │(models.py) │      │
│         └────────────┘      └────────────┘      └────────────┘      └────────────┘      │
└─────────────────────────────────────────────┬───────────────────────────────────────────┘
                                              │
                      ┌───────────────────────┴───────────────────────┐
                      ▼                                               ▼
┌─────────────────────────────────────────────┐ ┌─────────────────────────────────────────┐
│            DATABASE LAYER                    │ │          INTEGRATION LAYER               │
│  ─────────────────────────────────────────  │ │  ─────────────────────────────────────  │
│                                             │ │                                         │
│  🐘 Cloud SQL (PostgreSQL 15)               │ │  💳 PAYMENT GATEWAY                     │
│     ─────────────────────────               │ │     ─────────────────────               │
│     Managed PostgreSQL on GCP               │ │     WireMock (Dev/Test)                 │
│     • Auto backups                          │ │     Razorpay (Production)               │
│     • High availability                     │ │     • UPI, Cards, NetBanking            │
│                                             │ │     • Webhook notifications             │
│     ─────────────────────────               │ │                                         │
│     Tables:                                 │ │  🤖 AI & WORKFLOW (Phase 2)             │
│     • users, profiles                       │ │     ─────────────────────               │
│     • health_plans, categories              │ │     Dialogflow CX                       │
│     • carts, cart_items                     │ │     • Conversation AI                   │
│     • orders, order_items                   │ │     • Multi-turn dialogs                │
│     • payments, transactions                │ │     Cloud Workflows                     │
│                                             │ │     • Orchestration                     │
│  Alternative: MySQL 8.0                     │ │     • Event-driven automation           │
│                                             │ │     Cloud Functions                     │
│                                             │ │     • Serverless compute                │
└─────────────────────────────────────────────┘ └─────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              DEVOPS & OBSERVABILITY                                      │
├─────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                         │
│   📂 GitHub                    🔄 CI/CD Pipeline              ☁️ GCP Services            │
│   ─────────────               ─────────────────              ─────────────────          │
│   • Source Code               GitHub Actions:                • Cloud Run                │
│   • Pull Requests             • Lint & Test                  • Cloud SQL                │
│   • Branch Protection         • Build Docker                 • Cloud Build              │
│   • Code Reviews              • Push to Artifact Registry    • Artifact Registry        │
│                               • Deploy to Cloud Run          • Secret Manager           │
│                               • Run DB Migrations            • Cloud Logging            │
│                               Cloud Build (Alternative):     • Cloud Monitoring         │
│                               • Native GCP CI/CD             • Dialogflow CX            │
│                               • Trigger on push              • Cloud Workflows          │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Part 3: Requirements Analysis

### 3.1 Noun-Verb Analysis

**Instructions:** Read the Business Requirements (Section 1.3) and identify:
1. **NOUNS** = Things/Entities → These become Database Tables/Models
2. **VERBS** = Actions → These become API Endpoints

---

#### NOUNS (→ Entities/Models)

| Noun | Description | Django App |
|------|-------------|------------|
| **Customer/User** | Person buying health plans | `accounts` app |
| **Admin** | HealthFirst staff member | `accounts` app |
| **HealthPlan** | Insurance plan for sale | `catalog` app |
| **Category** | Plan grouping (Individual, Family, Senior) | `catalog` app |
| **Cart** | Shopping basket for a customer | `cart` app |
| **CartItem** | Single plan entry in cart | `cart` app |
| **Order** | Completed purchase/enrollment | `orders` app |
| **OrderItem** | Single plan in an order | `orders` app |
| **Payment** | Payment transaction record | `payments` app |
| **PaymentGateway** | External payment service | Integration (WireMock) |
| **Chatbot** | AI assistant (Phase 2) | `chatbot` app |

#### VERBS (→ Actions/API Endpoints)

| Verb | Entity | API Action | HTTP Method | App |
|------|--------|------------|-------------|-----|
| create account | User | Register new customer | POST | accounts |
| log in | User | Authenticate | POST | accounts |
| log out | User | End session | POST | accounts |
| browse | HealthPlan | List all plans | GET | catalog |
| search | HealthPlan | Search plans | GET | catalog |
| view | HealthPlan | Get plan details | GET | catalog |
| add | CartItem | Add plan to cart | POST | cart |
| view | Cart | Get cart contents | GET | cart |
| modify/update | CartItem | Change quantity | PATCH | cart |
| remove | CartItem | Delete from cart | DELETE | cart |
| checkout | Cart | Initiate checkout | POST | orders |
| process | Payment | Process payment | POST | payments |
| generate | Order | Create order after payment | POST | orders |
| view | Order | Get order history | GET | orders |
| download | Order | Get policy document | GET | orders |
| add | HealthPlan | Create plan (admin) | POST | catalog |
| update | HealthPlan | Update plan (admin) | PUT | catalog |
| activate/deactivate | HealthPlan | Toggle plan status (admin) | PATCH | catalog |
| update | Order | Change order status (admin) | PATCH | orders |
| answer | Chatbot | Respond to FAQ (Phase 2) | POST | chatbot |
| recommend | Chatbot | Suggest plans (Phase 2) | POST | chatbot |

---

```text

customer_profile/
├── __init__.py
├── api/
│   ├── __init__.py
│   ├── signup_api.py
│   └── login_api.py
├── dto/
│   ├── __init__.py
│   ├── signup_dto.py
│   ├── login_dto.py
│   └── customer_response_dto.py
├── service/
│   ├── __init__.py
│   ├── customer_service.py          # Interface (ABC)
│   ├── customer_service_factory.py
│   └── impl/
│       ├── __init__.py
│       └── customer_service_impl.py
├── dao/
│   ├── __init__.py
│   ├── customer_dao.py              # Interface (ABC)
│   ├── customer_dao_factory.py
│   └── impl/
│       ├── __init__.py
│       └── customer_dao_impl.py
└── model/
    ├── __init__.py
    └── customer.py

```

## V2 Folders and Content Notes

### V2 Folder Structure

```text
python_flask_back_office/healthcare_plans_bo/
├── Dockerfile          # Existing V1 Dockerfile (keep as is)
├── Dockerfile.v2       # NEW - V2 Dockerfile
├── docker-compose.yml  # NEW - Run V1 and/or V2 locally
├── run_local.sh        # NEW - Developer script
│
└── v2/                 # NEW - V2 Module
    ├── __init__.py
    ├── config_v2.py
    ├── extensions_v2.py
    ├── main_v2.py
    ├── run_v2.py
    ├── requirements_v2.txt
    │
    ├── api/
    │   └── health.py
    │
    └── customer_profile/    # Domain Module (DDD)
        ├── api/
        │   ├── signup_api.py
        │   └── login_api.py
        ├── dto/
        │   ├── signup_dto.py
        │   ├── login_dto.py
        │   └── customer_response_dto.py
        ├── service/
        │   ├── customer_service.py       # Interface
        │   ├── customer_service_factory.py
        │   └── impl/
        │       └── customer_service_impl.py
        ├── dao/
        │   ├── customer_dao.py           # Interface
        │   ├── customer_dao_factory.py
        │   └── impl/
        │       └── customer_dao_impl.py
        └── model/
            └── customer.py
```

### V2  GitHub Workflows

```text
.github/workflows/
├── gcp-healthcare-bo-v2-cloud-run-deploy.yml
├── gcp-healthcare-bo-v2-cloud-run-health-check.yml
└── gcp-healthcare-bo-v2-cloud-run-destroy.yml
```

### V1 and V2 Local Development

```text
./run_local.sh          # Interactive menu
./run_local.sh v1       # Run V1 on port 8080
./run_local.sh v2       # Run V2 on port 8081
```

###  API Endpoints

VersionEndpointPortV1/api/v1/health/8080V2/api/v2/health8081V2/api/v2/customers/signup8081V2/api/v2/customers/login8081V2/api/v2/customers/me8081

## V2 Angular Setup

```shell

cd angular_front_end/healthcare_plans_ui

# Step 1: Create V2 Module with Routing
ng generate module v2 --routing

# Step 2: Create Core Module (Services, Guards, Interceptors)
ng generate module v2/core

# Step 3: Create Customer Profile Feature Module
ng generate module v2/customer-profile --routing

# Step 4: Create Services
# Auth service in core
ng generate service v2/core/services/auth

# Customer service in customer-profile
ng generate service v2/customer-profile/services/customer


# Step 5: Create Guards
ng generate guard v2/core/guards/auth --implements CanActivate

# Step 6: Create Interceptor
ng generate interceptor v2/core/interceptors/auth

# Step 7: Create Components
# Signup component
ng generate component v2/customer-profile/components/signup

# Login component
ng generate component v2/customer-profile/components/login

# Profile component (to view after login)
ng generate component v2/customer-profile/components/profile

# Step 8: Create Models/DTOs (manual files - Angular CLI doesn't have a generator for these)

# Create directories
mkdir -p src/app/v2/core/models
mkdir -p src/app/v2/customer-profile/dto

# Create empty files (we'll fill them with code)
touch src/app/v2/core/models/customer.model.ts
touch src/app/v2/customer-profile/dto/signup.dto.ts
touch src/app/v2/customer-profile/dto/login.dto.ts

# Step 9: Create Environment Config for API URL
# Check if environments folder exists, if not create it
mkdir -p src/environments


```

```text

After running these commands, your folder structure will look like:

src/app/v2/
├── v2.module.ts
├── v2-routing.module.ts
├── core/
│   ├── core.module.ts
│   ├── services/
│   │   └── auth.service.ts
│   ├── guards/
│   │   └── auth.guard.ts
│   ├── interceptors/
│   │   └── auth.interceptor.ts
│   └── models/
│       └── customer.model.ts
└── customer-profile/
    ├── customer-profile.module.ts
    ├── customer-profile-routing.module.ts
    ├── services/
    │   └── customer.service.ts
    ├── dto/
    │   ├── signup.dto.ts
    │   └── login.dto.ts
    └── components/
        ├── signup/
        │   ├── signup.component.ts
        │   ├── signup.component.html
        │   ├── signup.component.css
        │   └── signup.component.spec.ts
        ├── login/
        │   ├── login.component.ts
        │   ├── login.component.html
        │   ├── login.component.css
        │   └── login.component.spec.ts
        └── profile/
            ├── profile.component.ts
            ├── profile.component.html
            ├── profile.component.css
            └── profile.component.spec.ts

```

```shell

cd python_flask_back_office/healthcare_plans_bo
./run_local.sh # type 2 or select option 2
# python v2/run_v2.py

# Terminal 2 - Angular (port 4200)
cd angular_front_end/healthcare_plans_ui
ng serve

```

## V3 Local Development

For V3 local development with MySQL, you have two options:

1. Option 1: Docker MySQL (Recommended)
2. Option 2: Full Docker Setup

### Option 1:
```shell

# Start MySQL + phpMyAdmin only (no Flask container)
./run_local.sh mysql

# Then run Flask V3 locally
./run_local.sh v3

./run_local.sh stop 

```

#### Access:
- MySQL: localhost:4306
- phpMyAdmin:       http://localhost:8081
- phpMyAdmin:       http://localhost:8083                   root / root_password
- Health Check:     http://localhost:8082/api/v3/health     root / root_password
- Flask V3 API      http://localhost:8082
- MySQL             localhost:3306                          healthcare_app / healthcare_password

### Option 2:
```shell
# Start everything (MySQL + Flask + phpMyAdmin)
./run_local.sh
# Choose option 6

```

