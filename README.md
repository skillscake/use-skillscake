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
directory or run `npx skills add skillscake/use-skillscake`.

Claude Code plugin: `/plugin marketplace add skillscake/use-skillscake`, then
`/plugin install skillscake@skillscake`, then `/reload-plugins` to activate it.

Codex plugin: CLI `codex plugin marketplace add skillscake/use-skillscake`, 
then enable it from `/plugins`, then restart Codex to load the skill.

Copilot CLI plugin: `/plugin marketplace add skillscake/use-skillscake`, then 
`/plugin install skillscake@skillscake`, then restart Copilot to load the skill.

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
    plugins/             Claude Code, Codex, and Copilot plugin wrappers (symlink the skill)
    .claude-plugin/, .agents/, .github/plugin/   marketplace manifests

## License

[Apache License 2.0](LICENSE). Use, modify, and redistribute freely. This client
is open source; the upgrade engine and API stay a hosted service, and your use of
the API is governed by the SkillsCake terms.
