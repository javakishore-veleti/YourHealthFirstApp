"""
Flask V3 Entry Point
Location: v3/run_v3.py

Run this file to start the V3 application locally
Usage: python v3/run_v3.py
"""

import os
import sys

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from v3.main_v3 import app

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    debug = os.getenv('FLASK_ENV', 'development') == 'development'
    
    print(f"""
╔══════════════════════════════════════════════════════════════╗
║           YourHealthPlans API - V3 (MySQL)                   ║
╠══════════════════════════════════════════════════════════════╣
║  Server:    http://localhost:{port}                            ║
║  Health:    http://localhost:{port}/api/v3/health              ║
║  Swagger:   http://localhost:{port}/api/v3/docs (if enabled)   ║
╚══════════════════════════════════════════════════════════════╝
    """)
    
    app.run(host='0.0.0.0', port=port, debug=debug)
