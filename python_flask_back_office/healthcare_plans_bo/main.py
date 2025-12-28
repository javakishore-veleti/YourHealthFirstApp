"""
Flask Application Factory
"""
import os
from flask import Flask, jsonify
from config import config
from extensions import db, migrate, jwt, cors


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
