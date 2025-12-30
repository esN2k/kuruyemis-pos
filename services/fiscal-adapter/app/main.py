import logging
from uuid import uuid4

from fastapi import FastAPI

from app.config import settings
from app.models import SaleRequest, SaleResponse

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("fiscal-adapter")

app = FastAPI(title="Fiscal Adapter Stub", version="0.1.0")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/fiscal/sale", response_model=SaleResponse)
def fiscal_sale(payload: SaleRequest) -> SaleResponse:
    logger.info("Received sale request: total=%s lines=%s", payload.total, len(payload.lines))
    logger.info("Target device %s:%s app_no=%s", settings.device_ip, settings.device_port, settings.app_no)

    # TODO: Implement GMP3 message framing and send via TCP socket.
    # TODO: Handle ACK/NAK, retries, and timeouts.
    # TODO: Map response to fiscal receipt number.

    placeholder = f"STUB-{uuid4().hex[:8]}"
    return SaleResponse(
        status="stub",
        fiscal_receipt_no=placeholder,
        message="GMP3 adapter not implemented yet",
    )