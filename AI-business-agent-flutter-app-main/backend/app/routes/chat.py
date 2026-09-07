from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class ChatRequest(BaseModel):
    prompt: str


@router.post("/chat")
def chat(payload: ChatRequest | None = None, prompt: str | None = None):
    effective_prompt = prompt or (payload.prompt if payload else "")
    return {
        "response": f"FastAPI chat endpoint is ready for AI model integration. Prompt: {effective_prompt or 'empty'}",
        "prompt": effective_prompt,
    }
