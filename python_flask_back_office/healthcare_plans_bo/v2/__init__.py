"""
V2 Flask Application Module
Location: python_flask_back_office/healthcare_plans_bo/v2/__init__.py

This module contains the V2 implementation with:
- Modular monolith architecture (DDD)
- Customer Profile domain module
- Interface + Implementation pattern for Service and DAO layers
- Factory pattern for dependency injection
"""

from .main_v2 import create_app

__all__ = ['create_app']
