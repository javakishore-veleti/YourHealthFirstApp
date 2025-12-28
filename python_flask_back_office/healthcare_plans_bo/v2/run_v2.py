"""
Application Entry Point for V2
Location: python_flask_back_office/healthcare_plans_bo/v2/run_v2.py
"""

import os
import sys

# Add parent directory to path so we can import v2 module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from v2.main_v2 import create_app

# Get config from environment variable or default to development
config_name = os.environ.get('FLASK_ENV', 'development')

# Create Flask app
app = create_app(config_name)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    debug = config_name == 'development'
    
    print(f"""
    ╔══════════════════════════════════════════════════════════════╗
    ║           YourHealthPlans API Server (V2)                    ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Environment: {config_name:<44} ║
    ║  Port: {port:<50} ║
    ║  Debug: {str(debug):<49} ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Endpoints:                                                  ║
    ║  • GET  /api/v2/health           - Health check              ║
    ║  • POST /api/v2/customers/signup - Customer signup           ║
    ║  • POST /api/v2/customers/login  - Customer login            ║
    ║  • POST /api/v2/customers/refresh - Refresh token            ║
    ║  • GET  /api/v2/customers/me     - Get profile               ║
    ╚══════════════════════════════════════════════════════════════╝
    """)
    
    app.run(host='0.0.0.0', port=port, debug=debug)
