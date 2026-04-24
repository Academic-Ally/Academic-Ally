"""CrewAI agent definitions for PYQ Analyzer.

Five specialist agents. The manager is auto-provisioned by
Process.hierarchical in the Crew config.
"""
from crewai import Agent

from shared.llm import get_llm
from shared.tavily_tool import get_tavily_tool


AGENT_ROLE_TO_TRACKER = {
    "Syllabus Researcher": "syllabus",
    "Web Researcher": "webResearch",
    "Pattern Analyst": "pattern",
    "Question Predictor": "predictor",
    "Output Formatter": "formatter",
}

TRACKER_AGENT_NAMES = list(AGENT_ROLE_TO_TRACKER.values())


def build_pyq_agents():
    """Return the 5 specialist agents for PYQ Analyzer."""
    llm = get_llm(temperature=0.3)
    tavily_tool = get_tavily_tool()

    syllabus_researcher = Agent(
        role="Syllabus Researcher",
        goal=(
            "Produce the complete official topic list for the target subject "
            "in the target university and semester. Cite only topics that "
            "appear in the official curriculum."
        ),
        backstory=(
            "You are an expert in Indian engineering curricula with deep "
            "knowledge of Jawaharlal Nehru Technological University Hyderabad "
            "(JNTUH) and Osmania University (OU) syllabi across all B.E/B.Tech "
            "branches. You have spent years reviewing official syllabus documents "
            "and you refuse to invent topics that aren't in the curriculum. "
            "When uncertain, you say so rather than fabricate. You use the "
            "web_search tool when your knowledge is stale or the subject is "
            "obscure."
        ),
        llm=llm,
        tools=[tavily_tool],
        allow_delegation=False,
        verbose=True,
    )

    web_researcher = Agent(
        role="Web Researcher",
        goal=(
            "Find current, real-world information about the subject's past "
            "exam patterns — which topics have repeated, how questions are "
            "typically phrased, and any student-community insights on "
            "important questions."
        ),
        backstory=(
            "You are a research analyst specializing in Indian engineering "
            "education. You know how to query Tavily effectively for exam "
            "content. You always pair search results with the syllabus context "
            "you were given. You extract specific, actionable insights — never "
            "generic platitudes like 'study hard'. If a search returns nothing "
            "useful, you say so honestly."
        ),
        llm=llm,
        tools=[tavily_tool],
        allow_delegation=False,
        verbose=True,
    )

    pattern_analyst = Agent(
        role="Pattern Analyst",
        goal=(
            "Synthesize the syllabus and web research into a clear picture of "
            "exam conventions: how marks are distributed, what types of "
            "questions (2-mark definitions, 5-mark short, 10-mark long, "
            "16-mark essay) map to which topics, and which topics recur."
        ),
        backstory=(
            "You are an exam-pattern analyst with 10 years of experience "
            "decoding Indian engineering university papers. You think "
            "systematically about mark distribution and question taxonomy. "
            "You identify the top 5-6 topics by weight, estimate their "
            "percentage share of the paper, and flag which question-formats "
            "each topic tends to appear in."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    question_predictor = Agent(
        role="Question Predictor",
        goal=(
            "Generate 5-8 specific exam questions that are most likely to "
            "appear in the next semester's paper, each with a plausibility "
            "score between 0.3 and 0.95."
        ),
        backstory=(
            "You are a seasoned coaching-center instructor who has correctly "
            "predicted exam questions for years based on syllabus + past "
            "pattern analysis. You write questions in the exact style "
            "JNTUH/OU papers use — clear, often phrased as 'Explain...' or "
            "'Define...' or 'Derive...'. You assign realistic likelihoods — "
            "never all 0.95 (unrealistic) and never all 0.40 (unhelpful). "
            "Top topics get 0.75-0.90, mid-tier 0.50-0.70, long-shot 0.30-0.45. "
            "You never produce fewer than 5 questions."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    output_formatter = Agent(
        role="Output Formatter",
        goal=(
            "Assemble all prior agent outputs into the exact JSON structure "
            "the Flutter client expects, matching the PyqAnalysisOutput "
            "Pydantic schema."
        ),
        backstory=(
            "You are a precise data-formatter. You take the messy natural "
            "language outputs from earlier agents and produce clean, "
            "schema-conformant JSON. You never paraphrase or editorialize. "
            "topic_weights values sum to ~1.0 (tolerance 0.05). "
            "predicted_questions has at least 3 entries. Every field is "
            "populated; no nulls for required fields."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    return {
        "syllabus_researcher": syllabus_researcher,
        "web_researcher": web_researcher,
        "pattern_analyst": pattern_analyst,
        "question_predictor": question_predictor,
        "output_formatter": output_formatter,
    }
