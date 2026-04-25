"""Vision extraction step (pre-crew).

Downloads the image from Firebase Storage, sends it to Gemini's
multimodal API via litellm, returns a structured text description of
the question. Called BEFORE the CrewAI crew kicks off so downstream
text-only agents have something to work with.

We treat this as a tracked agent ("vision") for UI purposes — the
caller updates the progress tracker after we return.
"""
import base64
import logging
import os

import litellm
from firebase_admin import storage


logger = logging.getLogger(__name__)


VISION_MODEL = "gemini/gemini-2.5-flash"


VISION_PROMPT = """\
You are an OCR + visual reasoning agent reading a photo of a student's
exam doubt. Your job is to extract the question text in a clear,
machine-readable form so a downstream solver can work on it.

Produce ONLY the following structured output (no preamble, no markdown):

QUESTION:
<the full question text, including any "given" data, "find", "explain",
or instructions. If there's a diagram, also describe it briefly inside
this section in (parentheses).>

GIVEN VALUES:
<bulleted list of any specific numerical values, variables, formulas,
or quantities provided. If none, write "(none)".>

WHAT TO FIND:
<one short sentence describing what is being asked.>

If the image does not contain a readable question (blank, photo of a
person, totally illegible scribble), output exactly:

NO_QUESTION_DETECTED
"""


async def extract_question_from_image(storage_id: str) -> str:
    """Read image from Firebase Storage, run Gemini multimodal, return text.

    Returns the structured QUESTION/GIVEN/WHAT-TO-FIND block, or
    ``"NO_QUESTION_DETECTED"`` if the model couldn't read a question.
    """
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set; cannot run vision.")

    bucket = storage.bucket()
    blob = bucket.blob(storage_id)
    image_bytes = blob.download_as_bytes()
    logger.info("vision: downloaded %d bytes from %s", len(image_bytes), storage_id)

    b64 = base64.b64encode(image_bytes).decode("ascii")
    image_data_url = f"data:image/jpeg;base64,{b64}"

    response = await litellm.acompletion(
        model=VISION_MODEL,
        api_key=api_key,
        messages=[
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": VISION_PROMPT},
                    {
                        "type": "image_url",
                        "image_url": {"url": image_data_url},
                    },
                ],
            }
        ],
        temperature=0.2,
    )

    extracted = response["choices"][0]["message"]["content"].strip()
    logger.info("vision: extracted %d chars (preview: %s)", len(extracted), extracted[:120])
    return extracted
