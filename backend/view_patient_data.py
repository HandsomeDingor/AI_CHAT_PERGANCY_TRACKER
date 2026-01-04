# view_patient_data.py
from firebase_admin import credentials, firestore, initialize_app

# 初始化 Firebase
cred = credentials.Certificate("firebase-key.json")
initialize_app(cred)
db = firestore.client()

def get_patient_bp(patient_id: str):
    docs = (
        db.collection("records")  # ✅ 确保名字与 Firestore 一致
        .where("patient_id", "==", patient_id)
        .where("type", "==", "blood_pressure")
        .order_by("ts")
        .stream()
    )

    found = False
    print(f"\n--- Blood Pressure Records for Patient {patient_id} ---\n")
    for doc in docs:
        found = True
        data = doc.to_dict()
        print(f"Found document: {doc.id}")
        print(
            f"Week {data.get('week')}: "
            f"{data.get('systolic')} / {data.get('diastolic')} mmHg  "
            f"({data.get('ts')})"
        )
    if not found:
        print("⚠️ No records found. Check your collection name or field types.")

if __name__ == "__main__":
    get_patient_bp("3278935")
