"""CrewAI task definitions for Adversarial Examiner."""
from crewai import Task

from .schema import AdversarialExamOutput


def build_examiner_tasks(agents: dict):
    """Build the 4 ordered tasks."""
    select_topics = Task(
        description=(
            "Select 4-6 topics within {subject} ({university} {branch} "
            "Sem {sem}) where students typically lose marks.\n\n"
            "Process:\n"
            "1. Use search_subject_documents with queries like 'common "
            "   mistakes', 'distinguish between', 'note that', 'often "
            "   confused', 'difference between' against the indexed notes "
            "   and IMP Q&A docs.\n"
            "2. Cross-reference the topic-frequency in past papers (use "
            "   queries with each topic name).\n"
            "3. If the user supplied focus_topics: {focus_topics}, narrow "
            "   selection to those — but verify they are in the subject's "
            "   indexed material first.\n"
            "4. For each selected topic, write 1-2 sentences on WHY this "
            "   topic is high-risk for students, citing source filenames "
            "   where applicable."
        ),
        expected_output=(
            "Markdown list of 4-6 topics, each with a justification + "
            "source citation."
        ),
        agent=agents["topic_selector"],
    )

    mine_traps = Task(
        description=(
            "For each topic from the previous task, identify 1-2 SPECIFIC "
            "trap patterns examiners use. These are the question phrasings "
            "that target known confusions.\n\n"
            "Use search_subject_documents to look up actual past-paper "
            "question phrasings about each topic. Look for:\n"
            "- 'Differentiate between X and Y' (common confusion trap)\n"
            "- 'State the conditions under which...' (missing assumption trap)\n"
            "- 'What happens if...' (edge case trap)\n"
            "- 'Compare and contrast' (similar-concepts mix trap)\n"
            "- Questions that mix two related concepts in a misleading way\n\n"
            "For each trap pattern: name the trap_type, give the common "
            "student mistake it exposes, and cite the source where you "
            "saw similar phrasing. Generic 'students often forget' is "
            "useless — be specific."
        ),
        expected_output=(
            "Markdown list — per topic — with 1-2 trap patterns, each "
            "labeled with trap_type and source citation."
        ),
        agent=agents["trap_miner"],
        context=[select_topics],
    )

    generate_questions = Task(
        description=(
            "Generate {question_count} adversarial questions for "
            "{subject}.\n\n"
            "For EACH question:\n"
            "- Pick a topic + trap_type from the previous task.\n"
            "- Write a NEW question (not copied from past papers) that "
            "  follows the trap pattern.\n"
            "- Use search_subject_documents to verify the question SOUNDS "
            "  authentic in JNTUH/OU style.\n"
            "- Write the common_mistake students would make on this exact "
            "  question — be specific (e.g., 'they apply BCNF rules when "
            "  the question is actually about 3NF', not 'they get it wrong').\n"
            "- Write the correct_approach: a 1-2 sentence guide on how to "
            "  approach it correctly.\n"
            "- Assign expected_marks: 2 (definition), 5 (short), 10 "
            "  (medium), or 16 (long).\n"
            "- Assign difficulty: 'medium', 'hard', or 'very_hard'. Aim "
            "  for a mix — most should be 'hard'.\n"
            "- Record source_paper_ids: the resourceIds of any chunks "
            "  you referenced.\n\n"
            "Output as Markdown — one question per section with all "
            "fields labeled."
        ),
        expected_output=(
            f"{{question_count}} Markdown sections, each with all 8 fields "
            "(topic, question, trap_type, common_mistake, correct_approach, "
            "expected_marks, difficulty, source_paper_ids)."
        ),
        agent=agents["question_generator"],
        context=[select_topics, mine_traps],
    )

    format_output = Task(
        description=(
            "Assemble the question generator output into the final JSON "
            "structure. Do NOT paraphrase; only restructure.\n\n"
            "Schema:\n"
            "```\n"
            "{\n"
            "  \"subject\": str (must be exactly '{subject}'),\n"
            "  \"overall_focus\": \"single-sentence summary\",\n"
            "  \"questions\": [\n"
            "    {\n"
            "      \"topic\": str,\n"
            "      \"question\": str,\n"
            "      \"trap_type\": str,\n"
            "      \"common_mistake\": str,\n"
            "      \"correct_approach\": str,\n"
            "      \"expected_marks\": int (2-20),\n"
            "      \"difficulty\": 'medium'|'hard'|'very_hard',\n"
            "      \"source_paper_ids\": [str, ...]\n"
            "    }, ... (at least 3)\n"
            "  ]\n"
            "}\n"
            "```\n\n"
            "Every field must be populated. Return ONLY the JSON. No "
            "code fences, no commentary."
        ),
        expected_output=(
            "A single JSON object matching AdversarialExamOutput schema."
        ),
        agent=agents["output_formatter"],
        context=[mine_traps, generate_questions],
        output_pydantic=AdversarialExamOutput,
    )

    return [select_topics, mine_traps, generate_questions, format_output]
