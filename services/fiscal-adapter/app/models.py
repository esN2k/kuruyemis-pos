from pydantic import BaseModel


class SaleLine(BaseModel):
    item_code: str
    description: str | None = None
    quantity: float
    unit_price: float
    total: float


class SaleRequest(BaseModel):
    invoice_no: str | None = None
    currency: str = "TRY"
    total: float
    lines: list[SaleLine]


class SaleResponse(BaseModel):
    status: str
    fiscal_receipt_no: str | None = None
    message: str | None = None
