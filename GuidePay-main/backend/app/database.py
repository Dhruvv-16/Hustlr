from motor.motor_asyncio import AsyncIOMotorClient
from app.config import settings
import logging

logger = logging.getLogger(__name__)


class Database:
    client: AsyncIOMotorClient = None
    db = None


db_instance = Database()


async def connect_db():
    logger.info("Connecting to MongoDB...")
    try:
        db_instance.client = AsyncIOMotorClient(
            settings.mongodb_url,
            serverSelectionTimeoutMS=10000,
            connectTimeoutMS=10000,
        )
        # Test connection
        await db_instance.client.admin.command('ping')
        db_instance.db = db_instance.client[settings.mongodb_db_name]
        await create_indexes()
        logger.info("MongoDB connected successfully")
    except Exception as e:
        logger.error(f"MongoDB connection failed: {e}")
        logger.warning("Running without database — mock mode only")
        # Don't crash — let the app start
        # API endpoints will handle missing db gracefully


async def disconnect_db():
    if db_instance.client:
        db_instance.client.close()
        logger.info("MongoDB disconnected")


async def create_indexes():
    db = db_instance.db

    # Workers
    await db.workers.create_index("phone", unique=True)
    await db.workers.create_index("firebase_uid", unique=True)
    await db.workers.create_index([("zone", 1), ("city", 1)])

    # Policies
    await db.policies.create_index("worker_id")
    await db.policies.create_index([("worker_id", 1), ("status", 1)])

    # Claims
    await db.claims.create_index("worker_id")
    await db.claims.create_index("trigger_event_id")
    await db.claims.create_index([("worker_id", 1), ("created_at", -1)])
    await db.claims.create_index(
        [("worker_id", 1), ("trigger_event_id", 1)],
        unique=True,
    )
    await db.claims.create_index([("policy_id", 1), ("created_at", -1)])

    # Trigger events
    await db.trigger_events.create_index([("city", 1), ("created_at", -1)])
    await db.trigger_events.create_index("status")
    await db.trigger_events.create_index("event_hash", unique=True, sparse=True)

    # Payments
    await db.payments.create_index("razorpay_payment_id", unique=True)
    await db.payments.create_index("worker_id")

    # Support tickets
    await db.support_tickets.create_index("worker_id")
    await db.support_tickets.create_index([("worker_id", 1), ("updated_at", -1)])
    await db.support_tickets.create_index("status")

    # Notifications
    await db.notifications.create_index("worker_id")
    await db.notifications.create_index([("worker_id", 1), ("read", 1), ("created_at", -1)])

    # Payout audits
    await db.payout_audit_logs.create_index([("claim_id", 1), ("created_at", -1)])


def get_db():
    return db_instance.db
