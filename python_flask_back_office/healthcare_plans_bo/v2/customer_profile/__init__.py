"""
Customer Profile Domain Module (V2)
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/__init__.py

Structure:
- api/       : REST API endpoints (signup, login)
- dto/       : Data Transfer Objects
- service/   : Business logic (interface + impl)
- dao/       : Data Access Objects (interface + impl)
- model/     : Domain entities
"""

from .api import customer_bp
from .model import Customer

__all__ = ['customer_bp', 'Customer']
