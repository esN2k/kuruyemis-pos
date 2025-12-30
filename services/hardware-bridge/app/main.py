from fastapi import FastAPI

app = FastAPI(title="Hardware Bridge Stub", version="0.1.0")


@app.get("/health")
def health():
    return {"status": "ok"}