from fastapi import FastAPI, Depends
from sqlalchemy import text
from .database import get_db

app = FastAPI()

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.get("/dashboard")
def get_dashboard(db=Depends(get_db)):
    result = db.execute(text("SELECT 1")).fetchall()
    return {"data": [dict(row) for row in result]}
