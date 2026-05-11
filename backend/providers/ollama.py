"""Ollama provider - local models via Ollama."""

import os
from typing import AsyncIterator
import httpx
import json

from ..llm_provider import LLMProvider, Message, LLMResponse


class OllamaProvider(LLMProvider):
    provider_name = "ollama"

    def __init__(self):
        # Support both local and cloud Ollama instances
        self.host = os.getenv("OLLAMA_HOST", "http://localhost:11434")
        self.api_key = os.getenv("OLLAMA_API_KEY", "")  # For cloud Ollama if needed
        self.default_model = "llama2"

    async def health(self) -> bool:
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(f"{self.host}/api/tags", timeout=5)
            return resp.status_code == 200
        except Exception:
            return False

    async def list_models(self) -> list[str]:
        """List available Ollama models."""
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(f"{self.host}/api/tags", timeout=5)
                data = resp.json()
                return [f"ollama/{m['name']}" for m in data.get("models", [])]
        except Exception:
            return []

    async def chat(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> LLMResponse:
        """Send message to Ollama."""
        async with httpx.AsyncClient() as client:
            # Remove "ollama/" prefix if present
            model_name = model.replace("ollama/", "")

            payload = {
                "model": model_name,
                "messages": [{"role": m.role, "content": m.content} for m in messages],
                "stream": False,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens,
                },
            }
            resp = await client.post(
                f"{self.host}/api/chat",
                json=payload,
                timeout=300,
            )
            resp.raise_for_status()
            data = resp.json()
            return LLMResponse(
                content=data["message"]["content"],
                model=model,
                provider=self.provider_name,
            )

    async def stream(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> AsyncIterator[str]:
        """Stream response from Ollama."""
        async with httpx.AsyncClient() as client:
            # Remove "ollama/" prefix if present
            model_name = model.replace("ollama/", "")

            payload = {
                "model": model_name,
                "messages": [{"role": m.role, "content": m.content} for m in messages],
                "stream": True,
                "options": {
                    "temperature": temperature,
                    "num_predict": max_tokens,
                },
            }
            async with client.stream(
                "POST",
                f"{self.host}/api/chat",
                json=payload,
                timeout=300,
            ) as resp:
                resp.raise_for_status()
                async for line in resp.aiter_lines():
                    if line:
                        try:
                            data = json.loads(line)
                            if "message" in data:
                                yield data["message"].get("content", "")
                        except json.JSONDecodeError:
                            pass
