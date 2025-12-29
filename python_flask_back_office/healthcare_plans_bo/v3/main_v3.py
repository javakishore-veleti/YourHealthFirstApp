"""
Flask V3 Main Application
Healthcare Plans API with MySQL Database Support

Supports:
- Local development with Docker MySQL
- GCP Cloud Run with Cloud SQL MySQL
"""

import os
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from datetime import timedelta

from v3.config import Config
from v3.extensions import db, migrate
from v3.customer_profile.routes import customer_bp


def create_app(config_class=Config):
    """Application factory pattern"""
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    # Initialize CORS FIRST - before other extensions
    CORS(app, 
         origins=['http://localhost:4200', 'http://localhost:3000', '*'],
         methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
         allow_headers=['Content-Type', 'Authorization', 'X-Requested-With'],
         supports_credentials=True)
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    
    # Initialize JWT
    jwt = JWTManager(app)
    
    # Register blueprints
    app.register_blueprint(customer_bp, url_prefix='/api/v3/customers')
    
    # Health check endpoint
    @app.route('/api/v3/health', methods=['GET'])
    def health_check():
        """Health check endpoint with database connectivity test"""
        health_status = {
            'service': 'YourHealthPlans API V3',
            'status': 'healthy',
            'version': 'v3',
            'environment': os.getenv('FLASK_ENV', 'development'),
            'database': 'unknown'
        }
        
        # Test database connection
        try:
            db.session.execute(db.text('SELECT 1'))
            health_status['database'] = 'connected'
        except Exception as e:
            health_status['database'] = f'error: {str(e)}'
            health_status['status'] = 'degraded'
        
        return jsonify(health_status), 200 if health_status['status'] == 'healthy' else 503
    
    # Admin migration endpoint (for Cloud Run)
    @app.route('/api/v3/admin/migrate', methods=['POST'])
    def run_migrations():
        """Run database migrations (protected endpoint)"""
        from flask import request
        
        # Simple API key protection
        admin_key = request.headers.get('X-Admin-Key')
        expected_key = os.getenv('ADMIN_API_KEY', 'default-admin-key')
        
        if admin_key != expected_key:
            return jsonify({'error': 'Unauthorized'}), 401
        
        try:
            with app.app_context():
                db.create_all()
            return jsonify({'message': 'Migrations completed successfully'}), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    # Database initialization
    with app.app_context():
        try:
            # Import models to ensure they're registered
            from v3.customer_profile.models import Customer
            
            # Check if tables exist
            from sqlalchemy import inspect
            inspector = inspect(db.engine)
            existing_tables = inspector.get_table_names()
            
            if not existing_tables:
                db.create_all()
                print("✅ Database tables created")
            else:
                print(f"✅ Database tables already exist: {existing_tables}")
                
        except Exception as e:
            print(f"⚠️ Database initialization: {e}")
    
    return app


# Create the application instance
app = create_app()


if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    debug = os.getenv('FLASK_ENV', 'development') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug)
