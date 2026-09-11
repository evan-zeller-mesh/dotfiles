/**
 * Reflects pi session state in the tmux window pill.
 *
 * Reuses claude-tmux-status and the @claude_state window option so pi and
 * Claude Code share one visual language — the color mapping lives in
 * tmux/.tmux.conf and is not duplicated here.
 *
 * The three states mirror the Claude Code hook wiring in ~/.claude/settings.json:
 *
 *   busy     agent is working            (PreToolUse, UserPromptSubmit)
 *   waiting  a prompt is blocking on a   (PermissionRequest, Notification
 *            human answer                 matching permission_prompt|elicitation)
 *   idle     finished, awaiting input    (SessionStart, Stop)
 *
 * `waiting` is deliberately reserved for a live blocking prompt, not for turn
 * completion — matching Claude's `Stop -> idle` — so the pill only turns red
 * when something is actually stuck.
 *
 * The prompt signal is `herdr:blocked`, the cross-package convention emitted by
 * pi-ask-user and by guardrails' herdr adapter. It is ref-counted here because
 * each emitter signals independently and prompts can overlap.
 */

import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Absolute rather than PATH-resolved: pi may not inherit an interactive PATH. */
const STATUS_SCRIPT = join(homedir(), ".local", "bin", "claude-tmux-status");

const HERDR_BLOCKED = "herdr:blocked";

type State = "busy" | "waiting" | "idle";

export default function (pi: ExtensionAPI) {
	// Outside tmux there is no window to style.
	if (!process.env.TMUX_PANE) return;

	let running = false;
	let promptDepth = 0;
	let applied: State | undefined;

	const apply = () => {
		const state: State =
			promptDepth > 0 ? "waiting" : running ? "busy" : "idle";
		if (state === applied) return;
		applied = state;
		// Fire and forget: never add latency to the agent loop for cosmetics.
		pi.exec(STATUS_SCRIPT, [state], { timeout: 2000 }).catch(() => {});
	};

	// Registered for the process lifetime, not per session. session_shutdown
	// also fires on /new and /resume, and extensions are not reloaded for
	// those, so unsubscribing there would silently break later sessions.
	pi.events.on(HERDR_BLOCKED, (data) => {
		const active = (data as { active?: unknown } | undefined)?.active;
		if (active === true) promptDepth += 1;
		else if (active === false) promptDepth = Math.max(0, promptDepth - 1);
		else return;
		apply();
	});

	pi.on("session_start", () => {
		running = false;
		promptDepth = 0;
		apply();
	});

	// Mirrors UserPromptSubmit: go busy on submit rather than waiting for the
	// first tool call, so the pill reacts immediately.
	pi.on("input", (event) => {
		if (event.source !== "interactive") return;
		running = true;
		apply();
	});

	pi.on("agent_start", () => {
		running = true;
		apply();
	});

	// agent_settled rather than agent_end: agent_end still precedes automatic
	// retries, compaction, and queued follow-ups, which are not idle.
	pi.on("agent_settled", () => {
		running = false;
		apply();
	});

	pi.on("session_shutdown", () => {
		running = false;
		promptDepth = 0;
		applied = undefined;
		pi.exec(STATUS_SCRIPT, ["idle"], { timeout: 2000 }).catch(() => {});
	});
}
