"""
Health Check API for V2
Location: python_flask_back_office/healthcare_plans_bo/v2/api/health.py
"""

from flask import Blueprint, jsonify
from datetime import datetime

health_bp = Blueprint('health_v2', __name__)


@health_bp.route('/health', methods=['GET'])
@health_bp.route('/health/', methods=['GET'])
def health_check():
    """
    Health Check Endpoint
    
    GET /api/v2/health
    
    Response:
    {
        "status": "healthy",
        "service": "YourHealthPlans API V2",
        "version": "v2",
        "timestamp": "2024-01-01T00:00:00.000000"
    }
    """
    return jsonify({
        'status': 'healthy',
        'service': 'YourHealthPlans API V2',
        'version': 'v2',
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@health_bp.route('/', methods=['GET'])
def root():
    """
    Root Endpoint
    
    GET /api/v2/
    
    Response:
    {
        "message": "Welcome to YourHealthPlans API V2",
        "version": "v2",
        "endpoints": { ... }
    }
    """
    return jsonify({
        'message': 'Welcome to YourHealthPlans API V2',
        'version': 'v2',
        'endpoints': {
            'health': '/api/v2/health',
            'signup': '/api/v2/customers/signup',
            'login': '/api/v2/customers/login',
            'refresh_token': '/api/v2/customers/refresh',
            'profile': '/api/v2/customers/me'
        }
    }), 200
