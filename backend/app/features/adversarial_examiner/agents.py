"""CrewAI agent definitions for Adversarial Examiner.

Three specialist agents + an Output Formatter. Single subject per
request, so the standard ``search_subject_documents`` tool works as-is
(no multi-subject duplicate-name issue).
"""
from crewai import Agent

from app.shared.llm import get_llm
from app.shared.rag.search_tool import get_subject_search_tool


AGENT_ROLE_TO_TRACKER = {
    "Topic Selector": "topicSelector",
    "Trap Pattern Miner": "trapMiner",
    "Adversarial Question Generator": "questionGenerator",
    "Output Formatter": "formatter",
}

TRACKER_AGENT_NAMES = list(AGENT_ROLE_TO_TRACKER.values())


def build_examiner_agents(subject_key: str):
    """Return the 4 specialist agents for Adversarial Examiner."""
    llm = get_llm(temperature=0.5)  # higher creativity for trap generation
    rag_tool = get_subject_search_tool(subject_key)

    topic_selector = Agent(
        role="Topic Selector",
        goal=(
            "Select 4-6 topics within the subject where students typically "
            "lose marks — confused concepts, frequently-tested edge cases, "
            "or commonly-mismatched definitions."
        ),
        backstory=(
            "You are an exam pattern analyst. Use search_subject_documents "
            "with queries like 'common mistakes', 'note that', 'distinguish "
            "between', 'often confused' to find topics with known student "
            "weaknesses. Cross-reference with topic frequency in past papers. "
            "Pick topics that ARE on the syllabus and DO appear in past "
            "papers — never invent topics."
        ),
        llm=llm,
        tools=[rag_tool],
        allow_delegation=False,
        verbose=True,
    )

    trap_miner = Agent(
        role="Trap Pattern Miner",
        goal=(
            "For each selected topic, identify the SPECIFIC trap patterns "
            "examiners use — exact phrasings that target known confusions."
        ),
        backstory=(
            "You are a forensic pattern-matcher. Use search_subject_documents "
            "to look up actual past-paper question phrasings about the "
            "selected topics. You hunt for: 'differentiate between X and Y' "
            "(when X and Y are commonly confused), 'state the conditions "
            "under which' (missing assumptions trap), 'what happens if' "
            "(edge case probe), and questions that mix two related concepts "
            "in a misleading way. For each trap, cite the source filename "
            "+ page where you saw similar phrasing. Be specific — generic "
            "'students often forget' is useless."
        ),
        llm=llm,
        tools=[rag_tool],
        allow_delegation=False,
        verbose=True,
    )

    question_generator = Agent(
        role="Adversarial Question Generator",
        goal=(
            "Generate {question_count} new, never-seen questions that "
            "follow the trap patterns identified, calibrated to expose "
            "specific student blind spots."
        ),
        backstory=(
            "You design questions that LOOK like ordinary exam questions "
            "but secretly test whether the student really understands or "
            "is just pattern-matching from notes. For EACH question you "
            "generate, you also write: (1) what trap_type it represents, "
            "(2) the common_mistake students make on it, (3) the "
            "correct_approach. You assign expected_marks (2/5/10/16) and "
            "difficulty (medium/hard/very_hard). You may use "
            "search_subject_documents to verify your questions sound "
            "authentic to JNTUH/OU style."
        ),
        llm=llm,
        tools=[rag_tool],
        allow_delegation=False,
        verbose=True,
    )

    output_formatter = Agent(
        role="Output Formatter",
        goal=(
            "Assemble the question generator output into the exact JSON "
            "structure matching AdversarialExamOutput."
        ),
        backstory=(
            "You are a precise data-formatter. Each question MUST have "
            "all six fields populated: topic, question, trap_type, "
            "common_mistake, correct_approach, expected_marks, difficulty. "
            "Never leave any field blank. Difficulty must be one of "
            "'medium' / 'hard' / 'very_hard'. Output overall_focus as a "
            "single sentence summary."
        ),
        llm=llm,
        tools=[],
        allow_delegation=False,
        verbose=True,
    )

    return {
        "topic_selector": topic_selector,
        "trap_miner": trap_miner,
        "question_generator": question_generator,
        "output_formatter": output_formatter,
    }
