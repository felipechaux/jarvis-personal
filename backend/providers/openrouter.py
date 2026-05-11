"""OpenRouter provider - cloud models via OpenRouter API."""

import os
from typing import AsyncIterator
import httpx
import json

from ..llm_provider import LLMProvider, Message, LLMResponse


class OpenRouterProvider(LLMProvider):
    provider_name = "openrouter"

    def __init__(self):
        self.api_key = os.getenv("OPENROUTER_API_KEY", "")
        self.base_url = "https://openrouter.ai/api/v1"
        self.default_model = "openrouter/anthropic/claude-sonnet-4-6"

    async def health(self) -> bool:
        if not self.api_key:
            return False
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(
                    f"{self.base_url}/models",
                    headers={"Authorization": f"Bearer {self.api_key}"},
                    timeout=5,
                )
            return resp.status_code == 200
        except Exception:
            return False

    async def list_models(self) -> list[str]:
        """List available OpenRouter models from API."""
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(
                    f"{self.base_url}/models",
                    headers={"Authorization": f"Bearer {self.api_key}"},
                    timeout=10,
                )
                if resp.status_code == 200:
                    data = resp.json()
                    return [f"openrouter/{m['id']}" for m in data.get("data", [])]
        except Exception:
            pass

        # Fallback models if API fails
        return [
            "openrouter/anthropic/claude-sonnet-4-6",
            "openrouter/google/gemini-2.5-pro",
            "openrouter/meta-llama/llama-3.3-70b",
            "openrouter/deepseek/deepseek-r1",
        ]

    async def chat(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> LLMResponse:
        """Send message to OpenRouter."""
        async with httpx.AsyncClient() as client:
            payload = {
                "model": model.replace("openrouter/", ""),
                "messages": [{"role": m.role, "content": m.content} for m in messages],
                "temperature": temperature,
                "max_tokens": max_tokens,
            }
            resp = await client.post(
                f"{self.base_url}/chat/completions",
                json=payload,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                timeout=60,
            )
            resp.raise_for_status()
            data = resp.json()
            return LLMResponse(
                content=data["choices"][0]["message"]["content"],
                model=model,
                provider=self.provider_name,
                tokens_used=data.get("usage", {}).get("total_tokens", 0),
            )

    async def stream(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> AsyncIterator[str]:
        """Stream response from OpenRouter."""
        async with httpx.AsyncClient() as client:
            payload = {
                "model": model.replace("openrouter/", ""),
                "messages": [{"role": m.role, "content": m.content} for m in messages],
                "temperature": temperature,
                "max_tokens": max_tokens,
                "stream": True,
            }
            async with client.stream(
                "POST",
                f"{self.base_url}/chat/completions",
                json=payload,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                timeout=60,
            ) as resp:
                resp.raise_for_status()
                async for line in resp.aiter_lines():
                    if line.startswith("data: "):
                        try:
                            chunk = json.loads(line[6:])
                            if "choices" in chunk:
                                delta = chunk["choices"][0].get("delta", {})
                                if "content" in delta:
                                    yield delta["content"]
                        except json.JSONDecodeError:
                            pass
