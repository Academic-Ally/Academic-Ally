# Academic Ally — Agent Instructions

Read `CLAUDE.md` in this directory first, in full. It is the single orientation
file for ALL AI agents (Claude Code, Codex, or any other) and for any human
developer joining the project. It carries the repository structure, feature
inventory, AI backend architecture, Firestore/Storage schema, and the critical
gotchas list. Deep dives live in `docs/` (ARCHITECTURE, FIRESTORE_SCHEMA,
AGENTIC_FEATURES, etc.) — consult the relevant one before any non-trivial task.

## Hard rules (apply regardless of which agent/tool you are)

1. **Git identity:** All commits and pushes are authored as
   `DevShoaib78 <mohammedshoaibchy78@gmail.com>`. NEVER add
   `Co-Authored-By: Claude` / `Co-Authored-By: Codex` or any AI attribution
   trailer, session link, or "Generated with" footer to commit messages or PR
   bodies. Clean subject + body only.
2. **Push target:** `master` is the default and main line as of 2026-08-27; it
   holds the unified React Native + Flutter history. Push there, never
   force-push it, and leave `reactnative`, `prod-fixes`, `stable`, `dev-affan`
   and `flutteroptimalstate` untouched — they are preserved history.
3. **Workspace root ≠ project root.** This folder (`academic_ally/`) is the
   only active project. Its parent holds `Academic Ally Legacy/` (pre-Flutter
   React Native / web / Netlify-functions code — reference only, do not edit),
   `Shoaib Choudry Major/` and `Akram's Archive/` (non-technical presentation
   material), plus its own `CLAUDE.md`/`AGENTS.md` entry-point docs. Never place
   new project files there, and never put presentation material in this repo.
4. **User builds APKs manually.** Do not run `flutter build` — provide the
   command and output path instead.
5. **Live Firebase project (`academic-ally-app`) with real user data.** Do not
   run destructive Firestore/Storage operations without explicit confirmation.
6. **Quality bar is release-grade.** The user vibe-codes; the agent owns
   security, error handling, UX polish, and proactive risk flagging.

If anything in `CLAUDE.md` contradicts what you observe in the live code,
bucket, or Firestore, trust the live source and flag the discrepancy so the
doc gets fixed.
