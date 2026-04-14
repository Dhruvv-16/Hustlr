import os
import logging

logger = logging.getLogger(__name__)

REQUIRED_ENV_VARS = [
    "MONGODB_URL",
    "MONGODB_DB_NAME",
    "SECRET_KEY"
]

def check_env():
    """Validates that critical environment variables exist."""
    missing = []
    for var in REQUIRED_ENV_VARS:
        if not os.environ.get(var):
            missing.append(var)
            
    if missing:
        logger.error(f"CRITICAL ERROR: Missing required environment variables: {', '.join(missing)}")
        logger.error("Please configure them in your .env file or deployment environment.")
        # In a real environment, we'd sys.exit(1). Here we just warn.
    else:
        logger.info("Environment variables validated successfully. System is go.")
