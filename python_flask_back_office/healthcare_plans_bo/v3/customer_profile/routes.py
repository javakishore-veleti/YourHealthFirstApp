"""
Customer Profile Routes for V3
RESTful API endpoints for customer management
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, 
    create_refresh_token, 
    jwt_required, 
    get_jwt_identity,
    get_jwt
)
from datetime import datetime, timedelta

from v3.extensions import db
from v3.customer_profile.models import Customer, RefreshToken

customer_bp = Blueprint('customer', __name__)


@customer_bp.route('/signup', methods=['POST'])
def signup():
    """Register a new customer"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['email', 'password', 'first_name', 'last_name']
        for field in required_fields:
            if not data.get(field):
                return jsonify({
                    'success': False,
                    'message': f'{field} is required'
                }), 400
        
        # Check if email already exists
        existing_customer = Customer.query.filter_by(email=data['email'].lower()).first()
        if existing_customer:
            return jsonify({
                'success': False,
                'message': 'Email already registered'
            }), 409
        
        # Validate password strength
        password = data['password']
        if len(password) < 8:
            return jsonify({
                'success': False,
                'message': 'Password must be at least 8 characters long'
            }), 400
        
        # Create new customer
        customer = Customer(
            email=data['email'],
            password=password,
            first_name=data['first_name'],
            last_name=data['last_name'],
            mobile_number=data.get('mobile_number'),
            date_of_birth=data.get('date_of_birth'),
            address=data.get('address'),
            city=data.get('city'),
            state=data.get('state'),
            zip_code=data.get('zip_code')
        )
        
        db.session.add(customer)
        db.session.commit()
        
        # Generate tokens
        access_token = create_access_token(identity=str(customer.id))
        refresh_token = create_refresh_token(identity=str(customer.id))
        
        # Store refresh token
        store_refresh_token(customer.id, refresh_token)
        
        return jsonify({
            'success': True,
            'message': 'Registration successful',
            'data': {
                'customer': customer.to_dict(),
                'access_token': access_token,
                'refresh_token': refresh_token
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Registration failed: {str(e)}'
        }), 500


@customer_bp.route('/login', methods=['POST'])
def login():
    """Authenticate customer and return tokens"""
    try:
        data = request.get_json()
        
        # Validate required fields
        if not data.get('email') or not data.get('password'):
            return jsonify({
                'success': False,
                'message': 'Email and password are required'
            }), 400
        
        # Find customer
        customer = Customer.query.filter_by(email=data['email'].lower()).first()
        
        if not customer or not customer.check_password(data['password']):
            return jsonify({
                'success': False,
                'message': 'Invalid email or password'
            }), 401
        
        if not customer.is_active:
            return jsonify({
                'success': False,
                'message': 'Account is deactivated'
            }), 403
        
        # Update last login
        customer.update_last_login()
        
        # Generate tokens
        access_token = create_access_token(identity=str(customer.id))
        refresh_token = create_refresh_token(identity=str(customer.id))
        
        # Store refresh token
        store_refresh_token(customer.id, refresh_token)
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'data': {
                'customer': customer.to_dict(),
                'access_token': access_token,
                'refresh_token': refresh_token
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Login failed: {str(e)}'
        }), 500


@customer_bp.route('/me', methods=['GET'])
@jwt_required()
def get_profile():
    """Get current customer's profile"""
    try:
        customer_id = get_jwt_identity()
        customer = Customer.query.get(int(customer_id))
        
        if not customer:
            return jsonify({
                'success': False,
                'message': 'Customer not found'
            }), 404
        
        return jsonify({
            'success': True,
            'data': customer.to_dict()
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Failed to get profile: {str(e)}'
        }), 500


@customer_bp.route('/me', methods=['PUT'])
@jwt_required()
def update_profile():
    """Update current customer's profile"""
    try:
        customer_id = get_jwt_identity()
        customer = Customer.query.get(int(customer_id))
        
        if not customer:
            return jsonify({
                'success': False,
                'message': 'Customer not found'
            }), 404
        
        data = request.get_json()
        
        # Update allowed fields
        allowed_fields = ['first_name', 'last_name', 'mobile_number', 
                         'date_of_birth', 'address', 'city', 'state', 'zip_code']
        
        for field in allowed_fields:
            if field in data:
                setattr(customer, field, data[field])
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Profile updated successfully',
            'data': customer.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Failed to update profile: {str(e)}'
        }), 500


@customer_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """Refresh access token"""
    try:
        customer_id = get_jwt_identity()
        
        # Verify customer still exists and is active
        customer = Customer.query.get(int(customer_id))
        if not customer or not customer.is_active:
            return jsonify({
                'success': False,
                'message': 'Customer not found or inactive'
            }), 401
        
        # Generate new access token
        access_token = create_access_token(identity=str(customer_id))
        
        return jsonify({
            'success': True,
            'access_token': access_token
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Token refresh failed: {str(e)}'
        }), 500


@customer_bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    """Logout and revoke tokens"""
    try:
        customer_id = get_jwt_identity()
        
        # Revoke all refresh tokens for this customer
        RefreshToken.query.filter_by(
            customer_id=int(customer_id),
            is_revoked=False
        ).update({'is_revoked': True})
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Logged out successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Logout failed: {str(e)}'
        }), 500


@customer_bp.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    """Change customer password"""
    try:
        customer_id = get_jwt_identity()
        customer = Customer.query.get(int(customer_id))
        
        if not customer:
            return jsonify({
                'success': False,
                'message': 'Customer not found'
            }), 404
        
        data = request.get_json()
        
        # Validate required fields
        if not data.get('current_password') or not data.get('new_password'):
            return jsonify({
                'success': False,
                'message': 'Current password and new password are required'
            }), 400
        
        # Verify current password
        if not customer.check_password(data['current_password']):
            return jsonify({
                'success': False,
                'message': 'Current password is incorrect'
            }), 401
        
        # Validate new password
        if len(data['new_password']) < 8:
            return jsonify({
                'success': False,
                'message': 'New password must be at least 8 characters long'
            }), 400
        
        # Update password
        customer.set_password(data['new_password'])
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Password changed successfully'
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Failed to change password: {str(e)}'
        }), 500


def store_refresh_token(customer_id, token):
    """Store refresh token in database"""
    try:
        refresh_token = RefreshToken(
            customer_id=customer_id,
            token=token,
            expires_at=datetime.utcnow() + timedelta(days=30)
        )
        db.session.add(refresh_token)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        print(f"Failed to store refresh token: {e}")
