"""
Customer Profile - API Module
"""

from flask import Blueprint
from .signup_api import signup_bp
from .login_api import login_bp

# Create main customer blueprint for v2
customer_bp = Blueprint('customer_v2', __name__)

# Register sub-blueprints
customer_bp.register_blueprint(signup_bp)
customer_bp.register_blueprint(login_bp)

__all__ = ['customer_bp']
