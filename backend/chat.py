from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os
from openai import OpenAI
from firebase_admin import firestore
from main import db  

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

if not client.api_key:
    raise RuntimeError("OPENAI_API_KEY is not set in environment")

router = APIRouter()

class ChatRequest(BaseModel):
    session_id: str
    user_id: str
    message: str


@router.post("/chat")
def chat(req: ChatRequest):

    messages_ref = (
        db.collection("chats")
        .document(req.session_id)
        .collection("messages")
    )

    history_query = (
        messages_ref
        .order_by("ts", direction=firestore.Query.DESCENDING)
        .limit(6)
        .stream()
    )

    history = [{"role": "system", "content": "You are a helpful pregnancy assistant."}]

    for doc in reversed(list(history_query)):
        d = doc.to_dict()
        history.append({"role": d["role"], "content": d["text"]})

    history.append({"role": "user", "content": req.message})

    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=history,
            max_tokens=500,
            temperature=0.2,
        )
        choice = completion.choices[0]
        reply = choice.message.content.strip()
        finish_reason = choice.finish_reason

        if finish_reason == "length":
            reply += "\n\n(Note: reply was cut short due to length limit.)"
    except Exception as e:
        print("OpenAI error:", e)
        raise HTTPException(status_code=429, detail="AI quota exceeded or rate limited")


    messages_ref.add({
        "role": "assistant",
        "text": reply,
        "user_id": "assistant",
        "ts": firestore.SERVER_TIMESTAMP
    })

    return {"reply": reply}
