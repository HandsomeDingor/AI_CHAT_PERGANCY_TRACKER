from fastapi import FastAPI
import firebase_admin 
from firebase_admin import credentials, firestore, initialize_app
from fastapi.middleware.cors import CORSMiddleware  

app = FastAPI()

# ✅ CORS config – adjust origins as needed
origins = [
    # "http://localhost:3000",
    # "http://127.0.0.1:3000",
    # "http://localhost:5173",
    # "http://127.0.0.1:5173",
    # or for quick dev:
    "*",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,      # or ["*"] during development
    allow_credentials=True,
    allow_methods=["*"],        # important so OPTIONS is allowed
    allow_headers=["*"],
)


# Firebase initialization
if not firebase_admin._apps:
    cred = credentials.Certificate("firebase-key.json")
    initialize_app(cred)

db = firestore.client()

from chat import router as chat_router

# hook chat.py to main.py
app.include_router(chat_router, prefix="/api")

@app.get("/")
def root():
    return {"message": "Pregnancy Tracker Backend is running"}

# Example: save pregnancy record
@app.post("/patient/record")
def add_record(data: dict):
    db.collection("pregnancy_records").add(data)
    return {"status": "record added"}


