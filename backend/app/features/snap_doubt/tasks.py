"""CrewAI task definitions for Snap-a-Doubt.

Each task receives the prior task's output as ``context``. The
extracted question text is injected into the task descriptions via
``crew.akickoff(inputs=...)``.
"""
from crewai import Task

from .schema import DoubtSolutionOutput


def build_snap_doubt_tasks(agents: dict):
    """Build the 4 ordered tasks."""
    retrieve_notes = Task(
        description=(
            "The student snapped a doubt about {subject}. The Vision "
            "Extractor produced this structured question:\n\n"
            "----- BEGIN EXTRACTED QUESTION -----\n"
            "{extracted_question}\n"
            "----- END EXTRACTED QUESTION -----\n\n"
            "Your job: search the student's indexed {subject} notes for "
            "the most relevant theory, formulas, definitions, and worked "
            "examples that the solver will need to answer this question.\n\n"
            "Process:\n"
            "1. Identify 2-4 search queries that would surface the theory. "
            "   Examples: the main concept being asked, related techniques, "
            "   any specific terms in the question.\n"
            "2. Call search_subject_documents for each query (top_k=4).\n"
            "3. Pick the chunks that genuinely apply — quality over "
            "   quantity. 4-6 chunks is plenty.\n"
            "4. Output them as a Markdown list with: filename, page span, "
            "   and a 2-3 line excerpt of the most relevant part of each "
            "   chunk. The solver reads this verbatim — make it useful.\n\n"
            "If the indexed notes have nothing relevant, say so honestly "
            "and the solver will use general knowledge."
        ),
        expected_output=(
            "Markdown bullet list of 4-6 relevant chunks with filename, "
            "page span, and excerpt; OR an honest statement that the "
            "corpus has no relevant material."
        ),
        agent=agents["notes_retriever"],
    )

    solve_step_by_step = Task(
        description=(
            "Produce a step-by-step solution to this question:\n\n"
            "----- BEGIN EXTRACTED QUESTION -----\n"
            "{extracted_question}\n"
            "----- END EXTRACTED QUESTION -----\n\n"
            "Use the retrieved theory from the previous task as your "
            "reference.\n\n"
            "**CITATIONS — use this exact marker syntax**:\n"
            "Whenever you use a fact from the retrieved theory, append a "
            "machine-readable marker right after the relevant sentence: "
            "`[CITE:<resourceId>:<page>]` or "
            "`[CITE:<resourceId>:<page_start>-<page_end>]`.\n"
            "The resourceId is shown in the Notes Retriever's output as "
            "`(resourceId=XXXXXX, ...)` next to each chunk. Use that EXACT "
            "string — DO NOT use the filename. IDs are stable, filenames "
            "are not.\n"
            "Example:\n"
            "  'BCNF requires that for every non-trivial dependency, the "
            "  determinant is a superkey [CITE:iniYGTAsuyKWFh1Qklhq:47].'\n"
            "If you draw on general knowledge instead, say so once at the "
            "top of the relevant step (no marker).\n\n"
            "**MULTI-PART QUESTIONS — one step per part**:\n"
            "If the question has multiple labelled parts (1a, 1b, 1c, "
            "etc., or 'Q1', 'Q2', etc.), produce a SEPARATE step for "
            "EACH part. Do NOT combine multiple sub-questions into one "
            "mega-step. The student needs to read each sub-answer "
            "independently.\n\n"
            "Output format (Markdown):\n"
            "**Step 1**: <explanation>. <inline [CITE:...] markers>\n"
            "<LaTeX / formulas where useful>\n\n"
            "**Step 2**: <explanation>...\n\n"
            "...\n\n"
            "**Final Answer**: <single short answer string>\n\n"
            "Constraints:\n"
            "- For multi-part questions: one step per part (could be 4-8 "
            "  steps total). For single-question doubts: 3-7 steps.\n"
            "- Each step has clear, complete reasoning — no skipped "
            "  algebra, no 'as you can see' hand-waving.\n"
            "- For math, include LaTeX inline where it helps clarity.\n"
            "- The Final Answer must be a short string — a number, a "
            "  one-line phrase, or a comma-separated list for multi-part "
            "  questions (e.g. '1a: a, 1b: across, 1c: an, 1d: none').\n"
        ),
        expected_output=(
            "Markdown solution with numbered steps, [CITE:filename:page] "
            "markers, optional LaTeX, ending with a 'Final Answer:' line."
        ),
        agent=agents["step_solver"],
        context=[retrieve_notes],
    )

    validate_solution = Task(
        description=(
            "Review the solver's output above as a second opinion. The "
            "extracted question (for reference) was:\n\n"
            "----- BEGIN EXTRACTED QUESTION -----\n"
            "{extracted_question}\n"
            "----- END EXTRACTED QUESTION -----\n\n"
            "Inspect the solver's solution and answer:\n"
            "1. Does the final answer address what the question asked?\n"
            "2. Does each step follow logically from the previous?\n"
            "3. Are units / variables / formulas used correctly?\n"
            "4. Is anything unjustified or hand-wavy?\n\n"
            "If the solution is sound: say 'VALIDATED: solution is sound.'\n"
            "If you find issues: list them concisely as: "
            "'Step <N>: <issue>'. The formatter will weave notes into the "
            "appropriate step. Do NOT re-solve — review only."
        ),
        expected_output=(
            "Either 'VALIDATED: solution is sound.' or a bulleted list of "
            "step-level issues."
        ),
        agent=agents["solution_validator"],
        context=[solve_step_by_step],
    )

    format_output = Task(
        description=(
            "Assemble the prior tasks' outputs into the final JSON.\n\n"
            "The extracted_question field MUST be a clean, single-paragraph "
            "version of the QUESTION section from the Vision Extractor's "
            "output (which is shown below for reference). Do NOT paraphrase "
            "the substance — strip the 'GIVEN VALUES' / 'WHAT TO FIND' "
            "headers but keep all the content as one block of text.\n\n"
            "Reference (the original extracted_question from vision):\n"
            "----- BEGIN EXTRACTED QUESTION -----\n"
            "{extracted_question}\n"
            "----- END EXTRACTED QUESTION -----\n\n"
            "Output schema (Pydantic):\n"
            "```\n"
            "{\n"
            "  \"extracted_question\": str,\n"
            "  \"subject\": \"{subject}\",  // exact echo\n"
            "  \"topic\": str,  // your concise topic label\n"
            "  \"steps\": [\n"
            "    {\n"
            "      \"index\": 1,\n"
            "      \"description\": str,        // CITE markers REMOVED — see below\n"
            "      \"latex\": str | null,\n"
            "      \"citations\": [\n"
            "        {\n"
            "          \"filename\": str,         // exact filename from a [CITE:...] marker\n"
            "          \"page_start\": int,        // 1-indexed PDF page\n"
            "          \"page_end\": int          // = page_start for single-page\n"
            "        }, ...\n"
            "      ]\n"
            "    }, ...\n"
            "  ],\n"
            "  \"final_answer\": str\n"
            "}\n"
            "```\n\n"
            "Citation schema: each entry is\n"
            "```\n"
            "{\n"
            "  \"filename\": \"\",         // leave empty — backend fills it\n"
            "  \"resource_id\": str,         // the resourceId from the [CITE:...] marker\n"
            "  \"page_start\": int,\n"
            "  \"page_end\": int          // = page_start for single-page\n"
            "}\n"
            "```\n\n"
            "Rules:\n"
            "- index starts at 1, increments by 1.\n"
            "- **MULTI-PART QUESTIONS**: if the solver wrote one mega-step "
            "  covering parts 1a/1b/1c/etc., SPLIT it into separate steps, "
            "  one per sub-part. Each step's description starts with the "
            "  sub-part label (e.g. '1a: <explanation>').\n"
            "- description: plain text, no Markdown. Strip leading 'Step N:' "
            "  labels. **REMOVE all `[CITE:resourceId:page]` markers** from "
            "  description text — they get extracted into the citations "
            "  list instead.\n"
            "- citations: for each [CITE:resourceId:page] marker the solver "
            "  wrote in this step, add an entry with `resource_id` set to "
            "  the resourceId and the page span parsed from the marker. "
            "  Parse `page_start-page_end` if it's a range (e.g. "
            "  `[CITE:abc123:5-7]`); otherwise page_start = page_end. "
            "  Leave `filename` as empty string — the backend post-step "
            "  fills it from the resource_id lookup.\n"
            "- Empty citations list if step had no markers.\n"
            "- latex: if the step contains a meaningful formula, put it "
            "  here (no $ delimiters). Otherwise null.\n"
            "- subject: must equal '{subject}' exactly.\n"
            "- If the validator flagged issues for a step, weave a short "
            "  note into that step's description.\n"
            "- final_answer: a single short string.\n\n"
            "Return ONLY the JSON. No commentary, no code fences."
        ),
        expected_output=(
            "A single JSON object matching DoubtSolutionOutput schema, "
            "with citation markers stripped from descriptions and parsed "
            "into the citations list."
        ),
        agent=agents["output_formatter"],
        context=[solve_step_by_step, validate_solution],
        output_pydantic=DoubtSolutionOutput,
    )

    return [retrieve_notes, solve_step_by_step, validate_solution, format_output]
