from fastapi import FastAPI

app = FastAPI(title="fulfillment-worker")


@app.get("/healthz")
def healthz():
    return {"status": "ok", "service": "fulfillment-worker"}
