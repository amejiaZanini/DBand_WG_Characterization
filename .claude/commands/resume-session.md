---
description: Load the most recent session file (repo .claude/session-data/ first, then ~/.claude/session-data/) and resume work with full context from where the last session ended.
---

# Resume Session Command

Load the last saved session state and orient fully before doing any work.
This command is the counterpart to `/save-session`.

## When to Use

- Starting a new session to continue work from a previous day
- After starting a fresh session due to context limits
- When handing off a session file from another source (just provide the file path)
- Any time you have a session file and want Claude to fully absorb it before proceeding

## Usage

```
/resume-session                                                      # most recent file: repo .claude/session-data/ first, then ~/.claude/session-data/
/resume-session 2024-01-15                                           # loads most recent session for that date
/resume-session .claude/session-data/2024-01-15-abc123de-session.md  # loads a specific repo session file
/resume-session ~/.claude/session-data/2024-01-15-abc123de-session.tmp  # loads a container-local session file
```

> **This repo is ephemeral between sessions.** `~/.claude/session-data/` is wiped
> when a new container starts, so the only session files that survive are the ones
> committed to the repo at `.claude/session-data/`. That folder is searched first.

## Process

### Step 1: Find the session file

If no argument provided:

1. Check the repo folder `.claude/session-data/` FIRST (relative to the project
   root — this is the only location that persists across containers), then fall
   back to `~/.claude/session-data/`.
2. Read the matching `*-session.md` and `*-session.tmp` candidates from both and
   apply the candidate ranking below across all of them.
3. Load the highest-ranked candidate.
4. If neither folder exists or has no eligible matching files, tell the user:
   ```
   No session files found in .claude/session-data/ or ~/.claude/session-data/
   Run /save-session at the end of a session to create one.
   ```
   Then stop.

If an argument is provided:

- If it looks like a date (`YYYY-MM-DD`), search the repo `.claude/session-data/` first, then
  `~/.claude/session-data/`, then the legacy `~/.claude/sessions/`, for files matching
  `YYYY-MM-DD-session.tmp` (legacy), `YYYY-MM-DD-<shortid>-session.tmp`, or
  `YYYY-MM-DD-<shortid>-session.md` (repo form), apply the candidate ranking below across
  all matches, and load the highest-ranked candidate for that date
- If it looks like a file path, read exactly that file directly. Do not apply candidate ranking or
  substitute a different file, even if the requested file is empty or another file is newer
- If not found, report clearly and stop

#### Candidate ranking for implicit and date-based lookup

Rank only automatically discovered candidates. Never use this ranking for an explicit file path.

1. Reject files that are unreadable, empty, whitespace-only, or contain only headings, metadata,
   separators, and placeholder values such as `[Session context goes here]`, `- [ ]`, a lone `-`,
   or `[relevant files]`.
2. Reject generated summaries with only one task and no populated files-modified, tools-used,
   completed, in-progress, notes, or context-to-load content. This structural rule filters
   one-message summarizer echoes without depending on any particular prompt text.
3. Keep candidates with substantive populated content: completed work, in-progress work, concrete
   next-session notes, concrete context paths, multiple tasks, modified files, or tools used.
4. Among eligible substantive candidates, prefer the newest modification time.
5. If modification times are equal, prefer more populated sections, then more non-placeholder
   content, then larger byte size, then the lexicographically smaller resolved path. Count populated
   sections and content only after removing headings, metadata, separators, and placeholder text.
   These final tie-breaks make selection deterministic.

### Step 2: Read the entire session file

Read the complete file. Do not summarize yet.

### Step 3: Confirm understanding

Respond with a structured briefing in this exact format:

```
SESSION LOADED: [actual resolved path to the file]
════════════════════════════════════════════════

PROJECT: [project name / topic from file]

WHAT WE'RE BUILDING:
[2-3 sentence summary in your own words]

CURRENT STATE:
PASS: Working: [count] items confirmed
 In Progress: [list files that are in progress]
 Not Started: [list planned but untouched]

WHAT NOT TO RETRY:
[list every failed approach with its reason — this is critical]

OPEN QUESTIONS / BLOCKERS:
[list any blockers or unanswered questions]

NEXT STEP:
[exact next step if defined in the file]
[if not defined: "No next step defined — recommend reviewing 'What Has NOT Been Tried Yet' together before starting"]

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

### Step 4: Wait for the user

Do NOT start working automatically. Do NOT touch any files. Wait for the user to say what to do next.

If the next step is clearly defined in the session file and the user says "continue" or "yes" or similar — proceed with that exact next step.

If no next step is defined — ask the user where to start, and optionally suggest an approach from the "What Has NOT Been Tried Yet" section.

---

## Edge Cases

**Multiple sessions for the same date** (`2024-01-15-session.tmp`, `2024-01-15-abc123de-session.tmp`):
Apply the candidate ranking across every matching legacy and current-format file. A substantive
session must win over a newer placeholder or one-message summarizer echo; modification time decides
between eligible candidates.

**Session file references files that no longer exist:**
Note this during the briefing — "WARNING: `path/to/file.ts` referenced in session but not found on disk."

**Session file is from more than 7 days ago:**
Note the gap — "WARNING: This session is from N days ago (threshold: 7 days). Things may have changed." — then proceed normally.

**User provides a file path directly (e.g., forwarded from a teammate):**
Read it and follow the same briefing process — the format is the same regardless of source.

**Session file is empty or malformed:**
For implicit or date-based discovery, reject it and continue ranking the remaining candidates. If no
eligible candidate remains, report: "Session files were found but appear empty or unreadable. You may
need to create a new one with /save-session." For an explicit path, report that the requested file is
empty or unreadable without loading a substitute.

---

## Example Output

```
SESSION LOADED: .claude/session-data/2026-05-10-export-retry-session.md
════════════════════════════════════════════════

PROJECT: my-project — chunk-level retry/backoff for the export job

WHAT WE'RE BUILDING:
A retry wrapper so transient failures don't abort a whole export run. Failed
chunks retry with backoff; after N attempts a chunk is skipped and logged.

CURRENT STATE:
Working: 2 items (backoff wrapper, per-chunk error log)
 In Progress: export/retry.* (constants still hardcoded)
 Not Started: configurable attempts/delay, skipped-chunk metric

WHAT NOT TO RETRY:
Batch-level retries — one bad chunk forced a full re-export, run never finished.

OPEN QUESTIONS / BLOCKERS:
Should all-attempts-failed fail the job, or just skip-and-log?

NEXT STEP:
Extract the max-attempts / base-delay magic numbers into constants, then add the
"all attempts fail" test.

════════════════════════════════════════════════
Ready to continue. What would you like to do?
```

---

## Notes

- Never modify the session file when loading it — it's a read-only historical record
- The briefing format is fixed — do not skip sections even if they are empty
- "What Not To Retry" must always be shown, even if it just says "None" — it's too important to miss
- After resuming, the user may want to run `/save-session` again at the end of the new session to create a new dated file
