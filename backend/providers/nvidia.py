"""NVIDIA provider - Nemotron models via NVIDIA API."""

import os
from typing import AsyncIterator
import httpx
import json

from ..llm_provider import LLMProvider, Message, LLMResponse


class NVIDIAProvider(LLMProvider):
    provider_name = "nvidia"

    def __init__(self):
        self.api_key = os.getenv("NVIDIA_API_KEY", "")
        self.base_url = "https://integrate.api.nvidia.com/v1"
        self.default_model = "nvidia/nemotron-4-340b-instruct"

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
        """List available NVIDIA models from API."""
        try:
            async with httpx.AsyncClient() as client:
                resp = await client.get(
                    f"{self.base_url}/models",
                    headers={"Authorization": f"Bearer {self.api_key}"},
                    timeout=10,
                )
                if resp.status_code == 200:
                    data = resp.json()
                    return [f"nvidia/{m['id']}" for m in data.get("data", [])]
        except Exception:
            pass

        # Fallback models if API fails
        return [
            "nvidia/nemotron-4-340b-instruct",
            "nvidia/nemotron-4-340b-base",
            "nvidia/nemotron-4-mini",
        ]

    async def chat(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> LLMResponse:
        """Send message to NVIDIA API."""
        try:
            async with httpx.AsyncClient() as client:
                model_name = model.replace("nvidia/", "")
                payload = {
                    "model": model_name,
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
        except httpx.HTTPStatusError as e:
            error_msg = f"NVIDIA API error: {e.response.status_code} - {e.response.text}"
            raise Exception(error_msg) from e
        except Exception as e:
            raise Exception(f"NVIDIA provider error: {str(e)}") from e

    async def stream(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> AsyncIterator[str]:
        """Stream response from NVIDIA API."""
        async with httpx.AsyncClient() as client:
            model_name = model.replace("nvidia/", "")
            payload = {
                "model": model_name,
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
