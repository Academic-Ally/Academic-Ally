"""CrewAI task definitions for PYQ Analyzer.

Tasks are chained — each one's ``context`` includes prior tasks so the
agent sees accumulated findings. The Output Formatter task produces the
final structured JSON.
"""
from crewai import Task

from .schema import PyqAnalysisOutput


def build_pyq_tasks(agents: dict):
    """Build the 5 ordered tasks for PYQ Analyzer."""
    research_syllabus = Task(
        description=(
            "Research and produce the official topic list for "
            "{subject} taught in {university} {course} {branch} Semester {sem}.\n\n"
            "Process:\n"
            "1. FIRST call search_subject_documents with queries like "
            "   '{subject} syllabus units', '{subject} chapters', "
            "   '{subject} course outline'. The subject's syllabus PDF "
            "   is indexed and is the ground truth.\n"
            "2. If the indexed syllabus is incomplete or missing, "
            "   supplement with web_search.\n"
            "3. List 5-8 major topics (units or chapters) from the "
            "   official curriculum.\n"
            "4. For each topic, include 2-3 sub-topics.\n"
            "5. Cite the syllabus filename + page for each topic where "
            "   indexed material is available.\n"
            "6. Do NOT invent topics. If information is genuinely "
            "   unavailable, say so.\n\n"
            "Format as Markdown with topic headings, bullet sub-topics, "
            "and an inline `(source: filename, page N)` after each topic."
        ),
        expected_output=(
            "A Markdown document with 5-8 H2 topic headings, 2-3 bullet "
            "sub-topics per heading, and source citations where available."
        ),
        agent=agents["syllabus_researcher"],
    )

    research_web = Task(
        description=(
            "Find information about past exam patterns for {subject} in "
            "{university} {branch} Semester {sem}.\n\n"
            "Process:\n"
            "1. FIRST call search_subject_documents on the indexed past "
            "   papers and OtherResources (which often contain 'IMP Q&A' "
            "   collections). Try queries like 'important questions', "
            "   'previous year', 'frequently asked', plus topic names from "
            "   the syllabus output above.\n"
            "2. THEN supplement with web_search for community insights — "
            "   'student community {subject} repeated questions', etc.\n\n"
            "Return a summary of 5-7 actionable insights about {subject} "
            "exam patterns. For each insight, label whether it came from "
            "[INDEXED] sources (cite filename + page) or [WEB] sources. "
            "If both layers return nothing useful, say so honestly — don't "
            "invent data."
        ),
        expected_output=(
            "A bulleted summary of 5-7 specific insights about {subject} "
            "exam patterns, each tagged [INDEXED: filename, page N] or "
            "[WEB] with a one-line justification."
        ),
        agent=agents["web_researcher"],
        context=[research_syllabus],
    )

    analyze_patterns = Task(
        description=(
            "Synthesize the syllabus and web research into exam-pattern "
            "analysis for {subject}.\n\n"
            "USE search_subject_documents AGGRESSIVELY here: search the "
            "indexed past papers / IMP Q&A docs for each major topic to "
            "count how often it appears and at what mark weights.\n\n"
            "Produce:\n"
            "1. A ranked list of the top 5-6 topics by expected weight "
            "   (each with a percentage 0-100% of the paper). Justify "
            "   each weight with a citation: 'appears in [filename, "
            "   page N] as a 10-mark question'.\n"
            "2. For each topic, the question formats it tends to appear in "
            "   (2-mark, 5-mark, 10-mark, 16-mark).\n"
            "3. An overall note on mark distribution (e.g., 'papers are "
            "   typically 30% short-answer, 70% long-answer')."
        ),
        expected_output=(
            "Markdown with a ranked topic list (topic name, % weight, typical "
            "question formats, source citations), plus a mark-distribution note."
        ),
        agent=agents["pattern_analyst"],
        context=[research_syllabus, research_web],
    )

    predict_questions = Task(
        description=(
            "Generate 5-8 specific exam questions for {subject} in {university} "
            "{branch} Semester {sem} that are most likely to appear.\n\n"
            "Process for EACH question:\n"
            "1. Use search_subject_documents to find similar past questions "
            "   from the indexed papers — model your prediction on the "
            "   actual phrasing style used.\n"
            "2. Write the question in the exact style used in JNTUH/OU papers.\n"
            "3. Assign an expected_marks value (2, 5, 10, or 16).\n"
            "4. Assign a likelihood between 0.30 and 0.95 (NEVER 1.0, NEVER 0.0).\n"
            "   Top 2-3 questions: 0.75-0.90. Middle tier: 0.50-0.70. "
            "   Long-shot: 0.30-0.45.\n"
            "5. Tag which topic the question belongs to (from the pattern "
            "   analysis).\n"
            "6. Record the source paper IDs you based the question on — list "
            "   the resourceIds from the search results.\n\n"
            "Output as Markdown — one question per section, with a 'Sources:' "
            "line listing the resource IDs."
        ),
        expected_output=(
            "5-8 Markdown sections, each with: Question text, Topic, "
            "Expected Marks, Likelihood, Sources (resource IDs)."
        ),
        agent=agents["question_predictor"],
        context=[research_syllabus, research_web, analyze_patterns],
    )

    format_output = Task(
        description=(
            "Assemble all prior agent outputs into the final JSON structure. "
            "Do NOT paraphrase; only restructure.\n\n"
            "The output JSON must match this Pydantic schema exactly:\n"
            "```\n"
            "{\n"
            "  \"subject\": str,\n"
            "  \"topic_weights\": {{topic_name: float_between_0_and_1}},  // values sum to ~1.0\n"
            "  \"predicted_questions\": [\n"
            "    {{\n"
            "      \"question\": str,\n"
            "      \"topic\": str,\n"
            "      \"expected_marks\": int (1-20),\n"
            "      \"likelihood\": float (0.0-1.0),\n"
            "      \"source_paper_ids\": []\n"
            "    }}, ... (at least 3 entries)\n"
            "  ],\n"
            "  \"source_resource_ids\": []\n"
            "}\n"
            "```\n\n"
            "The `subject` field must be exactly '{subject}'. topic_weights "
            "come from the Pattern Analyst output (convert percentages to "
            "decimals). predicted_questions come from the Question Predictor. "
            "Return ONLY the JSON — no surrounding Markdown, no commentary."
        ),
        expected_output=(
            "A single JSON object matching PyqAnalysisOutput schema. No "
            "code fences, no explanation."
        ),
        agent=agents["output_formatter"],
        context=[analyze_patterns, predict_questions],
        output_pydantic=PyqAnalysisOutput,
    )

    return [research_syllabus, research_web, analyze_patterns, predict_questions, format_output]
