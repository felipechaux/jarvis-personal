"""Jarvis Personal Assistant - Backend API."""

import os
import asyncio
import logging
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI, WebSocket, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional

# Load environment variables from .env file
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

from .llm_router import LLMRouter
from .llm_provider import Message

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Jarvis Personal Assistant")
router = LLMRouter()


# ── Request/Response Models ──────────────────────────


class ChatRequest(BaseModel):
    messages: list[dict]  # [{"role": "user", "content": "..."}]
    model: Optional[str] = None
    provider: Optional[str] = None  # Force specific provider
    temperature: float = 0.7
    max_tokens: int = 2048
    stream: bool = True


class ChatResponse(BaseModel):
    content: str
    model: str
    provider: str
    tokens_used: int = 0


# ── Health & Status ──────────────────────────────────


@app.get("/health")
async def health():
    """Check server health."""
    health = await router.health_check()
    return {
        "status": "ok",
        "providers": health,
    }


@app.get("/models")
async def list_models():
    """List all available models."""
    return await router.list_all_models()


# ── Chat Endpoints ──────────────────────────────────


@app.post("/chat")
async def chat(req: ChatRequest):
    """Send chat message (non-streaming)."""
    try:
        messages = [Message(role=m["role"], content=m["content"]) for m in req.messages]

        response = await router.chat(
            messages=messages,
            model=req.model,
            provider=req.provider,
            temperature=req.temperature,
            max_tokens=req.max_tokens,
        )

        return ChatResponse(
            content=response.content,
            model=response.model,
            provider=response.provider,
            tokens_used=response.tokens_used,
        )

    except Exception as e:
        error_msg = str(e)
        logger.error(f"Chat error: {error_msg}")

        # Check for specific error patterns
        if "402" in error_msg or "Payment Required" in error_msg:
            error_detail = f"OpenRouter API: Payment required. Check your API key and credits."
        elif "401" in error_msg or "Unauthorized" in error_msg:
            error_detail = f"OpenRouter API: Invalid or expired API key."
        elif "429" in error_msg or "Rate limit" in error_msg:
            error_detail = f"API rate limit exceeded. Please try again later."
        else:
            error_detail = f"Backend error: {error_msg}"

        # Return error in the same format as success response
        return ChatResponse(
            content=f"[Error] {error_detail}",
            model=req.model or "unknown",
            provider=req.provider or "unknown",
            tokens_used=0,
        )


@app.post("/chat/stream")
async def chat_stream(req: ChatRequest):
    """Stream chat response."""

    async def generate():
        try:
            messages = [
                Message(role=m["role"], content=m["content"]) for m in req.messages
            ]

            async for token in router.stream(
                messages=messages,
                model=req.model,
                provider=req.provider,
                temperature=req.temperature,
                max_tokens=req.max_tokens,
            ):
                yield token

        except Exception as e:
            error_msg = str(e)
            logger.error(f"Stream error: {error_msg}")

            # Format error message
            if "402" in error_msg:
                error_detail = "OpenRouter: Payment required. Check API key and credits."
            elif "401" in error_msg:
                error_detail = "OpenRouter: Invalid API key."
            elif "404" in error_msg:
                error_detail = "API endpoint not found. Check provider configuration."
            elif "429" in error_msg:
                error_detail = "Rate limit exceeded. Try again later."
            else:
                error_detail = f"Error: {error_msg}"

            yield f"\n[Error] {error_detail}"

    return StreamingResponse(generate(), media_type="text/plain")


# ── WebSocket for real-time conversation ──────────────


@app.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    """WebSocket for real-time conversational AI."""
    await websocket.accept()
    conversation = []

    try:
        while True:
            # Receive user message
            data = await websocket.receive_json()
            user_message = data.get("message", "")

            if not user_message:
                continue

            # Add to conversation history
            conversation.append({"role": "user", "content": user_message})

            # Stream response
            messages = [Message(role=m["role"], content=m["content"]) for m in conversation]
            response_text = ""

            await websocket.send_json({"status": "thinking"})

            async for token in router.stream(
                messages=messages,
                model=data.get("model"),
                provider=data.get("provider"),
                temperature=data.get("temperature", 0.7),
                max_tokens=data.get("max_tokens", 2048),
            ):
                response_text += token
                await websocket.send_json({"token": token})

            # Add assistant response to history
            conversation.append({"role": "assistant", "content": response_text})

            await websocket.send_json({"status": "done", "message": response_text})

    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        await websocket.send_json({"error": str(e)})
    finally:
        await websocket.close()


# ── Configuration ────────────────────────────────────


@app.post("/config/provider-priority")
async def set_provider_priority(priority: list[str]):
    """Change provider priority order."""
    router.set_provider_priority(priority)
    return {"priority": priority}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8000)
