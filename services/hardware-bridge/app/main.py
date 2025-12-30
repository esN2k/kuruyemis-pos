from fastapi import FastAPI

app = FastAPI(title="Donanım Köprüsü (Taslak)", version="0.1.0")


@app.get("/health")
def health():
    return {"durum": "tamam"}
