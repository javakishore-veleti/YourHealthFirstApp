"""
Signup API
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/api/signup_api.py
"""

from flask import Blueprint, request, jsonify
from v2.customer_profile.service import CustomerServiceFactory
from v2.customer_profile.dto import SignupRequestDTO

signup_bp = Blueprint('signup_v2', __name__)


@signup_bp.route('/signup', methods=['POST'])
def signup():
    """
    Customer Signup Endpoint
    
    POST /api/v2/customers/signup
    
    Request Body:
    {
        "email": "customer@example.com",
        "mobile_number": "9876543210",
        "password": "securepassword123",
        "first_name": "John",
        "last_name": "Doe"
    }
    
    Response (201):
    {
        "success": true,
        "message": "Account created successfully",
        "customer_id": 1,
        "email": "customer@example.com"
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'message': 'Request body is required'
            }), 400
        
        signup_request = SignupRequestDTO.from_dict(data)
        customer_service = CustomerServiceFactory.get_instance()
        response = customer_service.signup(signup_request)
        
        if response.success:
            return jsonify(response.to_dict()), 201
        else:
            return jsonify(response.to_dict()), 400
            
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }), 500
