import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    device_ip: str = os.getenv("FISCAL_DEVICE_IP", "192.168.1.50")
    device_port: int = int(os.getenv("FISCAL_DEVICE_PORT", "9100"))
    app_no: str = os.getenv("FISCAL_APP_NO", "1")
    timeout_seconds: int = int(os.getenv("FISCAL_TIMEOUT_SECONDS", "5"))


settings = Settings()
