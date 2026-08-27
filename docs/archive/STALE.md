# STALE — Archived Documentation

**Nothing in this folder is current. Do not use it to make decisions.**

These documents were accurate when written but describe plans that have since
been executed, or approaches that were abandoned. They are kept only so the
project's history is recoverable — an agent or developer should read the
**active** docs listed in `academic_ally/CLAUDE.md` (Documentation Map section)
and treat everything here as archaeology.

Archived on 2026-08-27.

---

## `AI_PIVOT_PLAN.md` — SUPERSEDED (plan fully executed)

The original 4-phase plan for turning Academic Ally into an AI-native platform.
Every phase it describes as pending has since shipped. Its most misleading claim
is that the AI features are "all built on mocks" — five of them run on real
multi-agent backends today.

**Read instead:** the Feature Inventory in `CLAUDE.md`, and
`docs/AGENTIC_FEATURES.md` for how the AI actually works.

---

## `FIREBASE_AUDIT.md` — SUPERSEDED (point-in-time snapshot, 2026-04-20)

An audit of which Firebase artifacts existed in the repo versus deployed. It
describes Firestore rules as "Console-only, permissive" and a "Phase 4 deploy
workflow (not yet executed)" — both since done: rules were written into the repo
and deployed 2026-04-25. It also predates the billing account closing.

**Read instead:** `docs/FIRESTORE_SCHEMA.md` (rules + index status per collection)
and the status banner in `CLAUDE.md`.

---

## `MIGRATION_NOTES.md` — COMPLETED WORK

Notes from the React Native to Flutter migration, including the RN-to-Flutter
screen mapping. The migration finished long ago and the Flutter app has since
grown well past feature parity, so this is a record of finished work rather than
a guide to anything pending.

**Read instead:** `docs/REACT_NATIVE_REFERENCE.md` if you need to check how the
original RN app behaved.

---

## `2026-04-20-phase-4-pyq-analyzer-implementation.md` — SUPERSEDED (plan executed)

A 3,582-line implementation plan for the PYQ Analyzer backend, written with the
Superpowers planning skill. The feature shipped; the surrounding architecture
then changed again when the local FastAPI platform (`backend/`) replaced the
Cloud Functions approach this plan targets.

**Read instead:** `docs/AGENTIC_FEATURES.md`.

---

## `2026-04-20-multi-agent-langgraph-design.md` — ABANDONED APPROACH

A design spec for building the multi-agent system on **LangGraph**. This was
never built. The project went with **CrewAI** instead (hierarchical process,
`crew_factory.py`). Useful only if someone revisits the framework decision.

**Read instead:** `docs/AGENTIC_FEATURES.md`.
