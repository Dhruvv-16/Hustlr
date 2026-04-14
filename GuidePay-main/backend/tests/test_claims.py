import pytest
from app.services.fraud_service import calculate_fraud_score
from datetime import datetime, timedelta


@pytest.mark.asyncio
async def test_fraud_score_duplicate_claim():
    """Duplicate claim should return score 1.0 and be rejected"""

    class MockDB:
        class claims:
            @staticmethod
            async def find_one(query):
                return {"_id": "existing-claim"}  # Simulate existing claim

    worker = {
        "_id": "worker-1",
        "zone_lat": 17.4401,
        "zone_lng": 78.3489,
        "risk_score": 0.75,
        "created_at": datetime.utcnow() - timedelta(days=30),
    }

    trigger_event = {
        "_id": "trigger-1",
        "started_at": datetime.utcnow(),
        "total_workers_in_zone": 100,
        "claims_count": 50,
    }

    result = await calculate_fraud_score(
        worker=worker,
        trigger_event=trigger_event,
        db=MockDB(),
    )

    assert result["score"] == 1.0
    assert "DUPLICATE_CLAIM" in result["flags"]
    assert result["decision"] == "REJECTED"


@pytest.mark.asyncio
async def test_fraud_score_clean_worker():
    """Clean worker with no claims should get low fraud score"""

    class MockDB:
        class claims:
            @staticmethod
            async def find_one(query):
                return None  # No existing claim

            @staticmethod
            async def count_documents(query):
                return 0  # No recent claims

            @staticmethod
            def aggregate(pipeline):
                class AsyncIter:
                    async def to_list(self, n):
                        return []
                return AsyncIter()

    worker = {
        "_id": "worker-clean",
        "zone_lat": 17.4401,
        "zone_lng": 78.3489,
        "risk_score": 0.85,
        "created_at": datetime.utcnow() - timedelta(days=180),
        "last_order_timestamp": datetime.utcnow() - timedelta(hours=1),
    }

    trigger_event = {
        "_id": "trigger-2",
        "started_at": datetime.utcnow(),
        "total_workers_in_zone": 100,
        "claims_count": 70,  # High correlation — should reduce score
    }

    result = await calculate_fraud_score(
        worker=worker,
        trigger_event=trigger_event,
        db=MockDB(),
    )

    assert result["score"] < 0.70
    assert result["decision"] == "AUTO_APPROVED"
