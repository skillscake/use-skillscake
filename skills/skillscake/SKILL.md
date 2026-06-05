---
name: skillscake
description: Create or upgrade an agent skill with SkillsCake. Use when the user wants to improve a skill using SkillsCake, create a skill based on a completed workflow, or says "use SkillsCake".
---

# SkillsCake

A skill is a directory containing one SKILL.md and a number of supporting files.

Send a skill to SkillsCake; it bakes a perfect version. You are the thin client: 
package the input, call the API, write the result back. The hard work is server-side.
You should only need to pause on error, tier choice, and apply gate.

## Flow

Two scripts: `scripts/check.sh` and `scripts/skillscake.sh`. Both print `key=value` 
lines; on error, follow `reason` and `action`.

1. **Mode.** *Upgrade* an existing skill folder, including useful sanitized conversation
   context, or *create* one from a workflow the user just completed and wants to reuse.
   For upgrade, you need to know the location of the skill now. Surface to the user if
   needed. Read all files in the skill quickly.

2. **Check** your connection and account. `bash scripts/check.sh`. If `status=error`, follow
   `action` and stop.

3. **Tier.** `base` for a small, single-purpose skill; `pro` for a
   substantial one (long, scripted, or multi-file). Pause here to ask the user, giving
   your recommendation, if they did not specify a tier when calling for SkillsCake. If
   they don't have the run credit they need, suggest they visit
   https://skillscake.com/account/plan.

4. **Write `notes.txt`, sanitized.** Describe the workflow. If context exists, consider
   steps, real inputs/outputs, and where judgment matters. Consider specific quotes from
   your work. You are the sanitizer: strip secrets,credentials, and customer PII; keep only
   what the skill needs to work.
   Note: between the skill and notes.txt you cannot exceed 30,000 characters.

5. **Run** (choose or make a tmp `OUT` dir; the finished skill lands at
   `OUT/<skill-name>/`, and the script prints its exact `skill_dir`):
   - Upgrade: `bash scripts/skillscake.sh --tier T --out OUT --skill DIR --notes notes.txt --label "<name>"`
   - Create: `bash scripts/skillscake.sh --tier T --out OUT --notes notes.txt --label "<name>"`
   On failure, follow `reason` / `action`.
   Note: the run takes ~10 minutes. Run the task in the background once submitted.

6. **Review.** Do a fast review of the new skill at `skill_dir`. Surface the
   skill and benefits to the user before moving to apply.

7. **Apply** the skill to the original live location, if approved by the user. For
   create, correctly add the skill to the user's skills depending on the harness.

## Don't

- Don't write or edit the skill yourself.
- Don't handle signup, cards, or plans; route the user to the website.
