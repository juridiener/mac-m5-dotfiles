#!/usr/bin/env node
// Global PreToolUse hook (Bash matcher): blocks a literal `grep` invocation and
// tells the caller to use `rg` instead. HARD BLOCK via exit 2 — deliberate,
// because the equivalent memory-only rule already failed once (a subagent ran
// `grep` after the rule was saved; subagents don't inherit personal memory).
//
// Fail-safe discipline: exit 2 = block, any OTHER non-zero exit or malformed
// output also blocks per Claude Code's PreToolUse contract, so a bug here has
// real blast radius (could block every Bash call). Every path below is wrapped
// so an unexpected error explicitly exits 0 (allow) rather than falling
// through to an accidental block.

function allow() {
  process.exit(0);
}

function block(reason) {
  process.stderr.write(reason + '\n');
  process.exit(2);
}

// Last-resort net: anything that escapes the try/catch below must still allow.
process.on('uncaughtException', allow);
process.on('unhandledRejection', allow);

try {
  let raw = '';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', (chunk) => {
    raw += chunk;
  });
  process.stdin.on('end', () => {
    try {
      const input = JSON.parse(raw);
      const command = input && input.tool_input && input.tool_input.command;
      if (typeof command !== 'string') return allow();

      // grep as the first token, or right after a shell operator (;, &&, ||, |, ().
      // Deliberately narrow: won't catch `xargs grep` / `find -exec grep`, and
      // won't false-positive on prose like `echo "use grep for X"`.
      const grepInvocation = /(^|[;&|(]\s*)grep\b/.test(command);
      if (!grepInvocation) return allow();

      // Only block if rg is actually available — no point blocking with no alternative.
      const { spawnSync } = require('child_process');
      const rgCheck = spawnSync('which', ['rg'], { encoding: 'utf8' });
      if (rgCheck.status !== 0) return allow();

      return block(
        '[prefer-rg] Bash `grep` is blocked in this environment — use `rg` instead (same flags, faster). ' +
          'Retry the command with `rg` in place of `grep`.'
      );
    } catch {
      return allow(); // malformed input or unexpected error — never block on uncertainty
    }
  });
} catch {
  allow();
}
