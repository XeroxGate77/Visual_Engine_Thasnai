# C.D. kit — Conjugated Dialectics

| File | What it is |
|---|---|
| `CD.md` | **The kit.** Philosophy, rules, aesthetic ideal, 5 modes (GAME · ART · CODE · SOUND · BOT), invariants. Single source of truth. Also a valid Agent Skill (has `name` / `description` frontmatter). |
| `cd.json` | The same numbers in machine-readable form. |
| `studio.html` | **C.D. Studio** — local app (open the file in any browser, no install, works offline). Read/edit the kit, then make a brief for Claude / Grok / ChatGPT in one of the 5 modes. Edits stay in the browser until you download them. |
| `studio.template.html` + `build_studio.py` | Rebuild Studio after editing `CD.md`: `python3 cd-kit/build_studio.py` |

## Use it with an AI
- **Any AI:** open Studio → pick a mode → write what you want → MAKE BRIEF → COPY → paste into the AI.
- **Upload:** drop `CD.md` into the chat, then say what to make and which mode.
- **Link:** after publishing, `https://xeroxgate77.github.io/engine77/cd/CD.md` (Studio: `…/engine77/cd/`). Only AIs that can open URLs can use the link.
- **Claude as a Skill:** put `CD.md` as `SKILL.md` in a folder named `conjugated-dialectics` inside your skills folder.

## Publish / update the link
Copy `CD.md`, `cd.json` and `studio.html` (as `index.html`) into `deploy/sd/cd/` and push the site repo.
