"""
Flask Application Factory for V2
Location: python_flask_back_office/healthcare_plans_bo/v2/main_v2.py
"""

from flask import Flask
from v2.config_v2 import config
from v2.extensions_v2 import db, jwt, cors, migrate


def create_app(config_name=None):
    """Application factory pattern for V2"""
    
    if config_name is None:
        config_name = 'development'
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    print(f"JWT_SECRET_KEY: {app.config.get('JWT_SECRET_KEY')[:20]}...")
    
    # Initialize extensions
    db.init_app(app)
    jwt.init_app(app)
    cors.init_app(app, resources={r"/api/*": {"origins": app.config.get('CORS_ORIGINS', '*')}})
    migrate.init_app(app, db)
    
    # Register blueprints
    register_blueprints(app)
    
    # Register error handlers
    register_error_handlers(app)
    
    # Register JWT error handlers
    register_jwt_handlers(app)
    
    # Create database tables
    with app.app_context():
        db.create_all()
    
    return app


def register_blueprints(app):
    """Register all domain module blueprints"""
    
    # Health check
    from v2.api.health import health_bp
    app.register_blueprint(health_bp, url_prefix='/api/v2')
    
    # Customer Profile module
    from v2.customer_profile.api import customer_bp
    app.register_blueprint(customer_bp, url_prefix='/api/v2/customers')


def register_error_handlers(app):
    """Register global error handlers"""
    
    from flask import jsonify
    
    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({
            'success': False,
            'error': 'Bad Request',
            'message': str(error.description) if hasattr(error, 'description') else 'Invalid request'
        }), 400
    
    @app.errorhandler(401)
    def unauthorized(error):
        return jsonify({
            'success': False,
            'error': 'Unauthorized',
            'message': 'Authentication required'
        }), 401
    
    @app.errorhandler(403)
    def forbidden(error):
        return jsonify({
            'success': False,
            'error': 'Forbidden',
            'message': 'Access denied'
        }), 403
    
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({
            'success': False,
            'error': 'Not Found',
            'message': 'Resource not found'
        }), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({
            'success': False,
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred'
        }), 500


def register_jwt_handlers(app):
    """Register JWT error handlers"""
    
    from flask import jsonify
    
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({
            'success': False,
            'error': 'Token Expired',
            'message': 'The token has expired. Please login again.'
        }), 401
    
    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return jsonify({
            'success': False,
            'error': 'Invalid Token',
            'message': 'Token verification failed.'
        }), 401
    
    @jwt.unauthorized_loader
    def missing_token_callback(error):
        return jsonify({
            'success': False,
            'error': 'Authorization Required',
            'message': 'Access token is missing.'
        }), 401
