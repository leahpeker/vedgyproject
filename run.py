"""Development server entry point"""
import os
from backend.app import create_app

app = create_app()

if __name__ == '__main__':
    # Use Railway's PORT environment variable or default to 8000
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)