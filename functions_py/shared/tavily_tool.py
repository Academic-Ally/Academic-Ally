"""CrewAI tool wrapping Tavily web search.

Agents that need real-time web context (e.g., the Web Researcher agent)
get this tool in their ``tools=[]`` list. The agent decides when to call
it; we don't pre-fetch.
"""
import os
from typing import List

from crewai.tools import BaseTool
from pydantic import BaseModel, Field
from tavily import TavilyClient


class TavilySearchInput(BaseModel):
    """Input schema for the Tavily search tool."""
    query: str = Field(..., description="Search query, as natural-language text")
    max_results: int = Field(5, description="Maximum results to return (1-10)")


class TavilyWebSearchTool(BaseTool):
    name: str = "web_search"
    description: str = (
        "Search the web for up-to-date information. Useful for finding "
        "current syllabi, past paper patterns, exam conventions, or any "
        "information that might have changed recently. Returns the top "
        "search results with titles, URLs, and content snippets."
    )
    args_schema: type[BaseModel] = TavilySearchInput

    def _run(self, query: str, max_results: int = 5) -> str:
        api_key = os.environ.get("TAVILY_API_KEY")
        if not api_key:
            return "ERROR: web_search unavailable — TAVILY_API_KEY not configured"
        client = TavilyClient(api_key=api_key)
        try:
            response = client.search(
                query=query,
                max_results=max(1, min(max_results, 10)),
                include_answer=False,
                search_depth="basic",
            )
        except Exception as exc:
            return f"ERROR: web_search failed — {exc}"

        results = response.get("results", [])
        if not results:
            return f"No web results for query: {query}"

        lines: List[str] = [f"Search results for: {query}", ""]
        for i, r in enumerate(results, start=1):
            title = r.get("title", "(no title)")
            url = r.get("url", "")
            content = r.get("content", "")[:500]
            lines.append(f"{i}. {title}\n   URL: {url}\n   Snippet: {content}\n")
        return "\n".join(lines)


def get_tavily_tool() -> TavilyWebSearchTool:
    """Factory for the CrewAI-compatible Tavily search tool."""
    return TavilyWebSearchTool()
