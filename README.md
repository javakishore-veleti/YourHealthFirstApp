# YourHealthFirstApp

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
### Macbook USERS ONLY COMMANDS END

### WINDOWS USERS ONLY COMMANDS START
if not exist healthcare_plans_bo mkdir healthcare_plans_bo
cd healthcare_plans_bo
if not exist requirements.txt type nul > requirements.txt
if not exist main.py type nul > main.py
if not exist __init__.py type nul > __init__.py
if not exist config.py type nul > config.py
if not exist extensions.py type nul > extensions.py
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