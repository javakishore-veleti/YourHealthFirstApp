# Flask V3 - Healthcare Plans API with MySQL

This is the V3 version of the Healthcare Plans API with full MySQL database support.

## Features

- MySQL database support (local Docker & GCP Cloud SQL)
- JWT authentication with refresh tokens
- Customer profile management
- Database migrations with Flask-Migrate
- Health check endpoint with database connectivity test

## Local Development

### Prerequisites

- Docker & Docker Compose
- Python 3.11+

### Quick Start with Docker

```bash
# Start all services (MySQL + Flask API + phpMyAdmin)
docker-compose -f docker-compose-v3.yml up -d

# View logs
docker-compose -f docker-compose-v3.yml logs -f flask-v3

# Stop all services
docker-compose -f docker-compose-v3.yml down

# Stop and remove volumes (clean slate)
docker-compose -f docker-compose-v3.yml down -v
```

### Access Points (Local)

| Service | URL |
|---------|-----|
| Flask API | http://localhost:8080 |
| Health Check | http://localhost:8080/api/v3/health |
| phpMyAdmin | http://localhost:8081 |

### Local Development without Docker

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements-v3.txt

# Set environment variables
export $(cat .env.v3.local | xargs)

# Run the application
python -m v3.main_v3
```

## API Endpoints

### Health Check
```
GET /api/v3/health
```

### Customer Authentication

```bash
# Signup
POST /api/v3/customers/signup
{
  "email": "user@example.com",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe"
}

# Login
POST /api/v3/customers/login
{
  "email": "user@example.com",
  "password": "password123"
}

# Get Profile (requires auth)
GET /api/v3/customers/me
Authorization: Bearer <access_token>

# Update Profile (requires auth)
PUT /api/v3/customers/me
Authorization: Bearer <access_token>
{
  "first_name": "Jane",
  "mobile_number": "+1234567890"
}

# Refresh Token
POST /api/v3/customers/refresh
Authorization: Bearer <refresh_token>

# Change Password (requires auth)
POST /api/v3/customers/change-password
Authorization: Bearer <access_token>
{
  "current_password": "password123",
  "new_password": "newpassword456"
}

# Logout (requires auth)
POST /api/v3/customers/logout
Authorization: Bearer <access_token>
```

## GCP Deployment

### Step 1: Create MySQL Database

```bash
# Run the MySQL workflow with action 'create'
# This creates:
# - Cloud SQL MySQL instance
# - Database and user
# - Credentials in Secret Manager
```

### Step 2: Deploy Flask V3

```bash
# Run the Flask V3 workflow with action 'deploy'
# This:
# - Retrieves database credentials from Secret Manager
# - Builds and deploys the Docker image to Cloud Run
# - Connects to the Cloud SQL database
```

### Step 3: Destroy (when done)

```bash
# 1. Destroy Flask V3 API
# Run Flask workflow with action 'destroy'

# 2. Destroy MySQL Database
# Run MySQL workflow with action 'destroy'
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| FLASK_ENV | Environment (development/production) | development |
| SECRET_KEY | Flask secret key | - |
| JWT_SECRET_KEY | JWT signing key | - |
| DB_HOST | Database host | localhost |
| DB_PORT | Database port | 3306 |
| DB_NAME | Database name | healthcare_db |
| DB_USER | Database user | healthcare_app |
| DB_PASSWORD | Database password | - |
| CLOUD_SQL_CONNECTION_NAME | GCP Cloud SQL connection | - |

## Database Schema

### customers table

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| email | VARCHAR(255) | Unique email |
| password_hash | VARCHAR(255) | Hashed password |
| first_name | VARCHAR(100) | First name |
| last_name | VARCHAR(100) | Last name |
| mobile_number | VARCHAR(20) | Phone number |
| date_of_birth | DATE | Date of birth |
| address | TEXT | Street address |
| city | VARCHAR(100) | City |
| state | VARCHAR(100) | State |
| zip_code | VARCHAR(20) | ZIP code |
| is_active | BOOLEAN | Account status |
| is_verified | BOOLEAN | Email verified |
| created_at | DATETIME | Creation timestamp |
| updated_at | DATETIME | Update timestamp |
| last_login | DATETIME | Last login time |

### refresh_tokens table

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| customer_id | INT | Foreign key to customers |
| token | VARCHAR(500) | Refresh token |
| expires_at | DATETIME | Expiration time |
| is_revoked | BOOLEAN | Token revoked |
| created_at | DATETIME | Creation timestamp |
