"""
Login API
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/api/login_api.py
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, create_access_token
from v2.customer_profile.service import CustomerServiceFactory
from v2.customer_profile.dto import LoginRequestDTO

login_bp = Blueprint('login_v2', __name__)


@login_bp.route('/login', methods=['POST'])
def login():
    """
    Customer Login Endpoint
    
    POST /api/v2/customers/login
    
    Request Body:
    {
        "email": "customer@example.com",
        "password": "securepassword123"
    }
    
    Response (200):
    {
        "success": true,
        "message": "Login successful",
        "data": {
            "access_token": "eyJ...",
            "refresh_token": "eyJ...",
            "customer": {
                "id": 1,
                "email": "customer@example.com",
                "full_name": "John Doe"
            }
        }
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'message': 'Request body is required'
            }), 400
        
        login_request = LoginRequestDTO.from_dict(data)
        customer_service = CustomerServiceFactory.get_instance()
        response = customer_service.login(login_request)
        
        if response.success:
            return jsonify(response.to_dict()), 200
        else:
            return jsonify(response.to_dict()), 401
            
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }), 500


@login_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """
    Refresh Access Token Endpoint
    
    POST /api/v2/customers/refresh
    
    Headers:
        Authorization: Bearer <refresh_token>
    
    Response (200):
    {
        "success": true,
        "access_token": "eyJ..."
    }
    """
    try:
        current_user_id = get_jwt_identity()
        new_access_token = create_access_token(identity=current_user_id)
        
        return jsonify({
            'success': True,
            'access_token': new_access_token
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }), 500


@login_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """
    Get Current User Profile
    
    GET /api/v2/customers/me
    
    Headers:
        Authorization: Bearer <access_token>
    
    Response (200):
    {
        "success": true,
        "data": { ... customer profile ... }
    }
    """
    try:
        current_user_id = get_jwt_identity()
        customer_service = CustomerServiceFactory.get_instance()
        profile = customer_service.get_profile(current_user_id)
        
        return jsonify({
            'success': True,
            'data': profile.to_dict()
        }), 200
        
    except ValueError as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 404
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }), 500
