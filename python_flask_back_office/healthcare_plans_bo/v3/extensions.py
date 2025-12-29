"""
Flask V3 Extensions
Centralized extension initialization
"""

from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

# Initialize extensions without app binding
db = SQLAlchemy()
migrate = Migrate()
