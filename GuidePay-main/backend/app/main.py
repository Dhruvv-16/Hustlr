from fastapi import FastAPI
from starlette.middleware.base import BaseHTTPMiddleware
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from time import perf_counter
import logging

from app.config import settings
from app.database import connect_db, disconnect_db
from app.routes import (
    auth, workers, policies, claims,
    triggers, payments, forecast, admin, support, notifications, public
)
from app.routes import actuarial, ml as ml_routes
from app.services.imd_service import start_trigger_scheduler
from app.services.auth_service import decode_token

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    from app.check_env import check_env
    check_env()
    
    from app.ml.ml_service import load_models
    from app.ml.train_models import train_and_save_all
    import os

    models_dir = os.path.join(os.path.dirname(__file__), "ml", "models")
    os.makedirs(models_dir, exist_ok=True)

    fraud_path = os.path.join(models_dir, "fraud_model.pkl")
    if not os.path.exists(fraud_path):
        logger.info("No trained ML models found; training bootstrap models")
        try:
            train_and_save_all()
        except Exception as exc:
            logger.warning(f"Model training failed: {exc}; continuing with rule-based fallback")

    load_models()
    await connect_db()
    await start_trigger_scheduler()
    logger.info("Guide-Pay API started")
    yield
    await disconnect_db()
    logger.info("Guide-Pay API stopped")


app = FastAPI(
    title="Guide-Pay API",
    description="Parametric income insurance for gig delivery workers",
    version="2.0.0",
    lifespan=lifespan,
)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        started = perf_counter()
        logger.info(f"{request.method} {request.url.path} - started")
        try:
            response = await call_next(request)
            duration_ms = round((perf_counter() - started) * 1000, 2)
            logger.info(
                f"{request.method} {request.url.path} - "
                f"{response.status_code} in {duration_ms}ms"
            )
            return response
        except Exception:
            duration_ms = round((perf_counter() - started) * 1000, 2)
            logger.exception(
                f"{request.method} {request.url.path} - failed in {duration_ms}ms"
            )
            raise


app.add_middleware(RequestLoggingMiddleware)


class AdminVerificationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        from fastapi.responses import JSONResponse
        protected_prefixes = ("/api/v1/admin", "/api/v1/actuarial", "/api/v1/support/admin")
        excluded_paths = {"/api/v1/auth/admin/login"}

        if request.url.path.startswith(protected_prefixes) and request.url.path not in excluded_paths:
            auth_header = request.headers.get("Authorization", "")
            if not auth_header.startswith("Bearer "):
                return JSONResponse({"detail": "Admin authorization required"}, status_code=401)
            try:
                payload = decode_token(auth_header.replace("Bearer ", "", 1))
            except Exception:
                return JSONResponse({"detail": "Admin token expired or invalid. Please log in again."}, status_code=401)
            if payload.get("role") != "admin":
                return JSONResponse({"detail": "Admin token required"}, status_code=403)
            request.state.admin = payload
        return await call_next(request)


app.add_middleware(AdminVerificationMiddleware)

# CORS — allow all origins for competition demo
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(workers.router, prefix="/api/v1/workers", tags=["workers"])
app.include_router(policies.router, prefix="/api/v1/policies", tags=["policies"])
app.include_router(claims.router, prefix="/api/v1/claims", tags=["claims"])
app.include_router(triggers.router, prefix="/api/v1/triggers", tags=["triggers"])
app.include_router(payments.router, prefix="/api/v1/payments", tags=["payments"])
app.include_router(forecast.router, prefix="/api/v1/forecast", tags=["forecast"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["admin"])
app.include_router(actuarial.router, prefix="/api/v1/actuarial", tags=["actuarial"])
app.include_router(support.router, prefix="/api/v1/support", tags=["support"])
app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["notifications"])
app.include_router(public.router, prefix="/api/v1/public", tags=["public"])
app.include_router(ml_routes.router, prefix="/api/v1/ml", tags=["ml"])


@app.get("/")
async def root():
    return {"service": "GuidePay API", "version": "3.0.0", "docs": "/docs"}


@app.get("/health")
async def health():
    return {"status": "healthy", "version": "3.0.0", "service": "GuidePay API"}
