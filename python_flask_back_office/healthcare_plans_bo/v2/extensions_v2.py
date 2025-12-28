"""
Flask Extensions for V2
Location: python_flask_back_office/healthcare_plans_bo/v2/extensions_v2.py
"""

from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_migrate import Migrate

db = SQLAlchemy()
jwt = JWTManager()
cors = CORS()
migrate = Migrate()
