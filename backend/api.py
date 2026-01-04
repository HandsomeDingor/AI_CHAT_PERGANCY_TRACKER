from fastapi import APIRouter
from firebase_admin import credentials, firestore, initialize_app
import firebase_admin

if not firebase_admin._apps:
    cred = credentials.Certificate("firebase-key.json")
    initialize_app(cred)

db = firestore.client()

router = APIRouter()

@router.get("/doctor/patient/{patient_id}/bp")
def get_patient_bp(patient_id: str):
    """
    获取指定病人的血压记录
    """
    docs = (
        db.collection("records")
        .where("patient_id", "==", patient_id)
        .where("type", "==", "blood_pressure")
        .order_by("ts")
        .stream()
    )

    result = []
    for d in docs:
        m = d.to_dict()
        result.append({
            "week": m.get("week"),
            "systolic": m.get("systolic"),
            "diastolic": m.get("diastolic"),
            "ts": m.get("ts"),
        })

    return {"patient_id": patient_id, "records": result}
