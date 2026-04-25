"""CrewAI agent definitions for Snap-a-Doubt.

Three CrewAI agents + a silent Output Formatter (4 Pydantic-validated
roles total). Plus a non-Crew "vision" pre-step that the caller tracks
manually — making four visible agent checkmarks in the UI.

AGENT_ROLE_TO_TRACKER includes ``Vision Extractor`` so the
make_crewai_step_callback (used elsewhere) leaves the vision tracker
untouched while still producing the final mapping for the UI.
"""
from crewai import Agent

from app.shared.llm import get_llm
from app.shared.rag.search_tool import get_subject_search_tool


# UI-visible agent order: vision (pre-crew) -> retriever -> solver -> validator.
# The Output Formatter is silent (no UI checkmark) — it's just structuring.
AGENT_ROLE_TO_TRACKER = {
    "Vision Extractor": "vision",
    "Notes Retriever": "retriever",
    "Step Solver": "solver",
    "Solution Validator": "validator",
}

TRACKER_AGENT_NAMES = list(AGENT_ROLE_TO_TRACKER.values())


def build_snap_doubt_agents(subject_key: str):
    """Return the 4 CrewAI agents (Vision Extractor is handled outside)."""
    llm = get_llm(temperature=0.3)
    rag_tool = get_subject_search_tool(subject_key)

    notes_retriever = Agent(
        role="Notes Retriever",
        goal=(
            "Pull the most relevant pieces of theory from the student's "
            "indexed notes for this specific question."
        ),
        backstory=(
            "You are a librarian who knows the subject's note corpus well. "
            "ALWAYS use search_subject_documents — multiple times if "
            "needed — to gather the theory, formulas, and definitions the "
            "solver will need. Search for: the topic of the question, any "
            "key terms or concepts in it, and related techniques. Cite "
            "filename + page for each chunk you keep. If the corpus has "
            "nothing relevant, say so honestly — solver will fall back to "
            "general knowledge."
        ),
        llm=llm,
        tools=[rag_tool],
        allow_delegation=False,
        verbose=True,
    )

    step_solver = Agent(
        role="Step Solver",
        goal=(
            "Produce a clean, step-by-step solution to the extracted "
            "question grounded in the retrieved theory, with citations."
        ),
        backstory=(
            "You are an excellent tutor — patient, methodical, no skipped "
            "steps. You consume the question text from the Vision "
            "Extractor and the theory chunks from the Notes Retriever, "
            "and produce a numbered solution where each step has a clear "
            "explanation. For mathematical content, include LaTeX where "
            "appropriate. Whenever you use a fact from the retrieved "
            "theory, append a citation 'see [filename] p.[page]'. End "
            "with a single short final answer string."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    solution_validator = Agent(
        role="Solution Validator",
        goal=(
            "Critically review the solver's output as a second opinion: "
            "does it actually answer the question? Are the steps logically "
            "sound? Are units consistent? Surface any flaws."
        ),
        backstory=(
            "You are a senior examiner who has seen every kind of mistake "
            "students make. Your job is NOT to re-solve — it's to inspect. "
            "Check: (1) does the final answer address what the question "
            "actually asked? (2) does each step follow from the previous? "
            "(3) are units / variables / formulas used correctly? (4) is "
            "anything unjustified or hand-wavy? If the solution is sound, "
            "say so concisely. If you find issues, list them with the "
            "step number — so the formatter can decide how to surface them."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    output_formatter = Agent(
        role="Output Formatter",
        goal=(
            "Assemble the prior outputs into the exact JSON shape "
            "matching DoubtSolutionOutput."
        ),
        backstory=(
            "You are a precise data-formatter. You produce one JSON "
            "object with all required fields populated. The `extracted_"
            "question` MUST come from the vision extractor's QUESTION "
            "section; do NOT paraphrase it. Step indices start at 1. "
            "If the validator flagged issues, weave brief notes into the "
            "relevant step's description rather than dropping them. "
            "source_pages is a list of distinct citations like 'EOITK "
            "Notes Unit 1 p.5' pulled from the solver's citations."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    return {
        "notes_retriever": notes_retriever,
        "step_solver": step_solver,
        "solution_validator": solution_validator,
        "output_formatter": output_formatter,
    }
