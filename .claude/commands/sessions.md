---
description: List and load saved session logs. Dependency-free (no Node library); reads the repo's .claude/session-data/ first, then ~/.claude/session-data/.
---

# Sessions

List, inspect and load the session logs written by `/save-session`. No external
library required — just read the folders.

## Where logs live
1. `.claude/session-data/` in the repo (committed → survives containers) — PRIMARY.
2. `~/.claude/session-data/` (container-local, legacy) — fallback.

Filenames: `YYYY-MM-DD-<short-id>-session.md` (repo) or `...-session.tmp` (legacy).

## Usage
```
/sessions                 # list all sessions, newest first
/sessions list            # same
/sessions load <id|date|name>   # print one session's full content
```

## list
Gather candidates from both folders and show date + topic, newest first:
```bash
for d in .claude/session-data ~/.claude/session-data; do
  [ -d "$d" ] || continue
  for f in "$d"/*-session.md "$d"/*-session.tmp; do
    [ -e "$f" ] || continue
    topic=$(grep -m1 '^\*\*Topic:\*\*' "$f" | sed 's/.*Topic:\*\* //')
    printf '%s\t%s\t%s\n' "$(date -r "$f" +%Y-%m-%d\ %H:%M)" "$(basename "$f")" "$topic"
  done
done | sort -r
```
Present the result as a short table: date · file · topic.

## load `<arg>`
Resolve `<arg>` against the filenames (a date `YYYY-MM-DD`, a short-id, or any
substring of the name), preferring the repo folder, then print the file:
```bash
arg="$1"
match=$(ls -t .claude/session-data/*-session.* ~/.claude/session-data/*-session.* 2>/dev/null \
        | grep -i -- "$arg" | head -1)
[ -n "$match" ] && { echo "== $match =="; cat "$match"; } || echo "No session matches: $arg"
```
If several match, list them and ask which one.

## Notes
- To RESUME (load the latest + get a briefing and continue), use `/resume-session`.
- To SAVE the current session, use `/save-session` (it commits the log to the repo).
- Aliases are not supported in this dependency-free version; refer to sessions by
  date or by a word from the filename.
