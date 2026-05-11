"""Google Gemini provider - free models via Google AI API."""

import os
from typing import AsyncIterator
import httpx
import json

from ..llm_provider import LLMProvider, Message, LLMResponse


class GeminiProvider(LLMProvider):
    provider_name = "gemini"

    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY", "")
        self.base_url = "https://generativelanguage.googleapis.com/v1beta/models"
        self.default_model = "gemini/gemini-1.5-flash"

    async def health(self) -> bool:
        if not self.api_key:
            return False
        try:
            async with httpx.AsyncClient() as client:
                # Use listModels endpoint which doesn't consume quota
                resp = await client.get(
                    f"{self.base_url}?key={self.api_key}",
                    timeout=5,
                )
            return resp.status_code == 200
        except Exception:
            return False

    async def list_models(self) -> list[str]:
        """List available Gemini models."""
        return [
            "gemini/gemini-2.5-flash",
            "gemini/gemini-2.5-pro",
            "gemini/gemini-2.0-flash",
        ]

    async def chat(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> LLMResponse:
        """Send message to Gemini API."""
        try:
            async with httpx.AsyncClient() as client:
                # Extract model name (remove "gemini/" prefix)
                model_name = model.replace("gemini/", "")

                # Convert messages to Gemini format
                contents = []
                for msg in messages:
                    contents.append({
                        "role": "user" if msg.role == "user" else "model",
                        "parts": [{"text": msg.content}]
                    })

                payload = {
                    "contents": contents,
                    "generationConfig": {
                        "temperature": temperature,
                        "maxOutputTokens": max_tokens,
                    }
                }

                resp = await client.post(
                    f"{self.base_url}/{model_name}:generateContent?key={self.api_key}",
                    json=payload,
                    headers={"Content-Type": "application/json"},
                    timeout=60,
                )

                if resp.status_code != 200:
                    error_msg = f"Gemini API error: {resp.status_code} - {resp.text}"
                    raise Exception(error_msg)

                data = resp.json()

                # Extract content from Gemini response
                if "candidates" in data and len(data["candidates"]) > 0:
                    candidate = data["candidates"][0]
                    if "content" in candidate and "parts" in candidate["content"]:
                        content = candidate["content"]["parts"][0].get("text", "")
                        return LLMResponse(
                            content=content,
                            model=model,
                            provider=self.provider_name,
                            tokens_used=0,
                        )

                raise Exception("Invalid response format from Gemini API")

        except Exception as e:
            raise Exception(f"Gemini provider error: {str(e)}") from e

    async def stream(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> AsyncIterator[str]:
        """Stream response from Gemini API."""
        try:
            async with httpx.AsyncClient() as client:
                # Extract model name (remove "gemini/" prefix)
                model_name = model.replace("gemini/", "")

                # Convert messages to Gemini format
                contents = []
                for msg in messages:
                    contents.append({
                        "role": "user" if msg.role == "user" else "model",
                        "parts": [{"text": msg.content}]
                    })

                payload = {
                    "contents": contents,
                    "generationConfig": {
                        "temperature": temperature,
                        "maxOutputTokens": max_tokens,
                    }
                }

                async with client.stream(
                    "POST",
                    f"{self.base_url}/{model_name}:streamGenerateContent?key={self.api_key}",
                    json=payload,
                    headers={"Content-Type": "application/json"},
                    timeout=60,
                ) as resp:
                    if resp.status_code != 200:
                        text = await resp.atext()
                        raise Exception(f"Gemini API error: {resp.status_code} - {text}")

                    async for line in resp.aiter_lines():
                        if line.strip():
                            try:
                                chunk = json.loads(line)
                                if "candidates" in chunk and len(chunk["candidates"]) > 0:
                                    candidate = chunk["candidates"][0]
                                    if "content" in candidate and "parts" in candidate["content"]:
                                        for part in candidate["content"]["parts"]:
                                            if "text" in part:
                                                yield part["text"]
                            except json.JSONDecodeError:
                                pass
        except Exception as e:
            raise Exception(f"Gemini stream error: {str(e)}") from e
