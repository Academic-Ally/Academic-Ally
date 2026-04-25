"""CrewAI agent definitions for PYQ Analyzer.

Five specialist agents. The manager is auto-provisioned by
``Process.hierarchical`` in the Crew config.

Four of the five agents get the RAG search tool (``search_subject_documents``)
bound to the request's subject. The Output Formatter is a pure
restructuring agent and needs no tools.
"""
from crewai import Agent

from app.shared.llm import get_llm
from app.shared.rag.search_tool import get_subject_search_tool
from app.shared.tavily_tool import get_tavily_tool


AGENT_ROLE_TO_TRACKER = {
    "Syllabus Researcher": "syllabus",
    "Web Researcher": "webResearch",
    "Pattern Analyst": "pattern",
    "Question Predictor": "predictor",
    "Output Formatter": "formatter",
}

TRACKER_AGENT_NAMES = list(AGENT_ROLE_TO_TRACKER.values())


def build_pyq_agents(subject_key: str):
    """Return the 5 specialist agents for PYQ Analyzer.

    Args:
        subject_key: Output of ``make_subject_key(...)``. Binds the RAG
            search tool to this subject's vector index.
    """
    llm = get_llm(temperature=0.3)
    tavily_tool = get_tavily_tool()
    rag_tool = get_subject_search_tool(subject_key)

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
            "branches. ALWAYS try search_subject_documents FIRST to read the "
            "actual syllabus PDFs uploaded for this subject — they are the "
            "ground truth. Fall back to web_search only if the indexed "
            "documents are insufficient. You refuse to invent topics that "
            "aren't in the curriculum. When uncertain, you say so rather "
            "than fabricate."
        ),
        llm=llm,
        tools=[rag_tool, tavily_tool],
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
            "education. ALWAYS try search_subject_documents FIRST — the "
            "subject's past papers and question banks are indexed and are "
            "the most reliable source for past exam patterns. Use Tavily "
            "web_search only to supplement (e.g., what's trending in the "
            "field this year, student forums). You extract specific, "
            "actionable insights — never generic platitudes like 'study "
            "hard'. Always cite filename + page when quoting indexed material."
        ),
        llm=llm,
        tools=[rag_tool, tavily_tool],
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
            "decoding Indian engineering university papers. ALWAYS use "
            "search_subject_documents to read the actual past papers and "
            "important-questions documents indexed for this subject — that "
            "is your ground truth for frequency analysis. You think "
            "systematically about mark distribution and question taxonomy. "
            "You identify the top 5-6 topics by weight, estimate their "
            "percentage share of the paper, and flag which question-formats "
            "each topic tends to appear in. Cite filename + page when "
            "claiming a topic is common."
        ),
        llm=llm,
        tools=[rag_tool],
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
            "pattern analysis. ALWAYS use search_subject_documents to look "
            "up actual past question phrasings before drafting predictions — "
            "your generated questions should mirror the indexed paper style "
            "exactly. Phrase questions like 'Explain...', 'Define...', "
            "'Derive...' just like JNTUH/OU papers do. Assign realistic "
            "likelihoods — never all 0.95 (unrealistic) and never all 0.40 "
            "(unhelpful). Top topics get 0.75-0.90, mid-tier 0.50-0.70, "
            "long-shot 0.30-0.45. You never produce fewer than 5 questions. "
            "Populate source_paper_ids with the resourceId of any chunk you "
            "based a question on."
        ),
        llm=llm,
        tools=[rag_tool],
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
