import logging
from uuid import uuid4

from fastapi import FastAPI

from app.config import settings
from app.models import SaleRequest, SaleResponse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mali-adapter")

app = FastAPI(title="Mali Adaptör (Taslak)", version="0.1.0")


@app.get("/health")
def health():
    return {"durum": "tamam"}


@app.post("/fiscal/sale", response_model=SaleResponse)
def fiscal_sale(payload: SaleRequest) -> SaleResponse:
    logger.info("Satış isteği alındı: toplam=%s satır=%s", payload.total, len(payload.lines))
    logger.info(
        "Hedef cihaz %s:%s uygulama_no=%s",
        settings.device_ip,
        settings.device_port,
        settings.app_no,
    )

    # YAPILACAK: GMP3 mesaj çerçeveleme ve TCP soket ile gönderim.
    # YAPILACAK: ACK/NAK, yeniden deneme ve zaman aşımı yönetimi.
    # YAPILACAK: Cihaz yanıtını mali fiş numarasına eşle.

    placeholder = f"TASLAK-{uuid4().hex[:8]}"
    return SaleResponse(
        status="taslak",
        fiscal_receipt_no=placeholder,
        message="GMP3 adaptörü henüz uygulanmadı",
    )
