"""Abstract LLM Provider interface - supports cloud & local models."""

from abc import ABC, abstractmethod
from typing import Optional, AsyncIterator
from dataclasses import dataclass


@dataclass
class Message:
    role: str  # "user" | "assistant" | "system"
    content: str


@dataclass
class LLMResponse:
    content: str
    model: str
    provider: str
    tokens_used: int = 0


class LLMProvider(ABC):
    """Abstract base for any LLM provider."""

    provider_name: str

    @abstractmethod
    async def chat(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> LLMResponse:
        """Send message, get response."""
        pass

    @abstractmethod
    async def stream(
        self,
        messages: list[Message],
        model: str,
        temperature: float = 0.7,
        max_tokens: int = 1024,
    ) -> AsyncIterator[str]:
        """Stream response tokens."""
        pass

    @abstractmethod
    async def list_models(self) -> list[str]:
        """List available models."""
        pass

    @abstractmethod
    async def health(self) -> bool:
        """Check if provider is available."""
        pass
