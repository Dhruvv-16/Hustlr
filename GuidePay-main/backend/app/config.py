from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    mongodb_url: str
    mongodb_db_name: str = "guidepay"

    firebase_project_id: str
    firebase_private_key_id: str
    firebase_private_key: str
    firebase_client_email: str
    firebase_client_id: str

    razorpay_key_id: str
    razorpay_key_secret: str
    razorpay_mock_mode: str = "true"

    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 10080
    admin_access_token_expire_minutes: int = 720

    frontend_url: str
    frontend_url_local: str = "http://localhost:5173"

    admin_username: str = "admin"
    admin_password: str = "admin"

    environment: str = "development"
    trigger_poll_interval_minutes: int = 15

    openweather_api_key: Optional[str] = ""

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
