"""LLM Router - intelligently routes requests between providers."""

from typing import AsyncIterator, Optional
import logging

from .llm_provider import LLMProvider, Message, LLMResponse
from .providers.openrouter import OpenRouterProvider
from .providers.nvidia import NVIDIAProvider
from .providers.gemini import GeminiProvider
from .providers.ollama import OllamaProvider

logger = logging.getLogger(__name__)


class LLMRouter:
    """Routes LLM requests with priority: Cloud (default) → Local (fallback)."""

    def __init__(self):
        # Initialize all providers
        self.providers = {
            "openrouter": OpenRouterProvider(),
            "gemini": GeminiProvider(),
            "nvidia": NVIDIAProvider(),
            "ollama": OllamaProvider(),
        }

        # Default priority: Cloud first (Gemini free, then OpenRouter), then local
        self.priority = ["gemini", "openrouter", "nvidia", "ollama"]
        self.current_provider = "gemini"

    async def health_check(self) -> dict[str, bool]:
        """Check health of all providers."""
        health = {}
        for name, provider in self.providers.items():
            try:
                health[name] = await provider.health()
            except Exception as e:
                logger.error(f"Health check failed for {name}: {e}")
                health[name] = False
        return health

    async def select_provider(self, preferred: Optional[str] = None) -> LLMProvider:
        """Select best available provider."""
        if preferred and preferred in self.providers:
            provider = self.providers[preferred]
            if await provider.health():
                self.current_provider = preferred
                return provider

        # Fall back to priority order
        for name in self.priority:
            provider = self.providers[name]
            if await provider.health():
                self.current_provider = name
                logger.info(f"Using {name} provider")
                return provider

        # If no provider available, default to OpenRouter (will fail if no key)
        return self.providers["openrouter"]

    async def chat(
        self,
        messages: list[Message],
        model: Optional[str] = None,
        provider: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> LLMResponse:
        """Send chat message using best available provider."""
        # Extract provider from model name if not explicitly provided
        if provider is None and model:
            model_prefix = model.split("/")[0]
            if model_prefix in self.providers:
                provider = model_prefix

        selected = await self.select_provider(provider)

        if model is None:
            model = selected.default_model

        return await selected.chat(messages, model, temperature, max_tokens)

    async def stream(
        self,
        messages: list[Message],
        model: Optional[str] = None,
        provider: Optional[str] = None,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> AsyncIterator[str]:
        """Stream chat using best available provider."""
        # Extract provider from model name if not explicitly provided
        if provider is None and model:
            model_prefix = model.split("/")[0]
            if model_prefix in self.providers:
                provider = model_prefix

        selected = await self.select_provider(provider)

        if model is None:
            model = selected.default_model

        async for token in selected.stream(messages, model, temperature, max_tokens):
            yield token

    async def list_all_models(self) -> dict[str, list[str]]:
        """List models from all available providers."""
        models = {}
        for name, provider in self.providers.items():
            if await provider.health():
                try:
                    models[name] = await provider.list_models()
                except Exception as e:
                    logger.error(f"Failed to list models for {name}: {e}")
        return models

    def set_provider_priority(self, priority: list[str]) -> None:
        """Change provider priority order."""
        self.priority = priority
        logger.info(f"Provider priority set to: {priority}")
