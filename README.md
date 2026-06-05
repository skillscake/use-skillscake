# SkillsCake

Create or improve an agent skill (`SKILL.md`) with [SkillsCake](https://skillscake.com).
Point it at a skill folder, or describe a workflow you just finished; it sends the
input to the SkillsCake API and writes a finished skill back. Built for prompt
engineers and skill builders who want skills that actually trigger and run well.

This repo is the public client; the upgrade engine stays a hosted service. The
skill follows the open [Agent Skills](https://agentskills.io) standard, so it
runs natively in Claude Code, Codex, and other agents.

## Install

Any host (the skill itself): copy `skills/skillscake/` into your agent's skills
directory — `~/.claude/skills/` (Claude Code) or `~/.agents/skills/` (Codex) — or
run `npx skills add skillscake/use-skillscake`.

Claude Code plugin: `/plugin marketplace add skillscake/use-skillscake`, then
`/plugin install skillscake@skillscake`.

Codex plugin: `codex plugin marketplace add skillscake/use-skillscake`, then enable
it from `/plugins`.

Needs `bash`, `curl`, `zip`, and `unzip` (standard on macOS and Linux).

## Set up a key

Create an API key at https://skillscake.com/account and export it:

    export SKILLSCAKE_API_KEY="skc_live_..."

A key runs skills only.

## Use

Ask your agent to "use SkillsCake" to upgrade a skill, or to turn a finished
workflow into one. It checks your runs, sanitizes and sends the input, and
applies the result — with as few questions as possible.

## Layout

    skills/skillscake/   the host-agnostic skill (SKILL.md + scripts)
    plugins/             Claude Code and Codex plugin wrappers (symlink the skill)
    .claude-plugin/, .agents/   marketplace manifests

## License

[Elastic License 2.0](LICENSE). Use and modify freely for personal or business
use; you may not resell it, or offer it (or SkillsCake's API) to others as a
hosted service. The client is source-available; the API and engine are not.
