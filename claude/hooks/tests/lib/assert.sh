#!/usr/bin/env bash
# Shared helpers for the hook test files. Source it, keep your own pass/fail counters.
#
# It exists for the two things every hook test needs and most were not doing: running a hook
# with its streams captured rather than discarded, and asserting on the message a blocked call
# shows Claude. An exit code alone says a call was refused; it does not say the refusal told
# anyone what to do instead, which for a PreToolUse guard is the whole product.

# hook_run <hook> <json-payload> [cwd]
# Sets HOOK_RC, HOOK_OUT and HOOK_ERR. Never fails the calling script, so a hook that dies
# is a reported case rather than an aborted run.
hook_run() {
  local hook=$1 json=$2 dir=${3:-$PWD}
  local scratch
  scratch=$(mktemp -d)
  printf '%s' "$json" | (cd "$dir" && bash "$hook") >"$scratch/out" 2>"$scratch/err"
  HOOK_RC=$?
  HOOK_OUT=$(cat "$scratch/out")
  HOOK_ERR=$(cat "$scratch/err")
  rm -rf "$scratch"
}

# Payload builders. Each prints one line of JSON.
payload_bash() {                    # payload_bash <command> [cwd]
  jq -n --arg c "$1" --arg d "${2:-$PWD}" \
    '{session_id:"t",hook_event_name:"PreToolUse",cwd:$d,tool_name:"Bash",
      tool_input:{command:$c}}'
}

payload_write() {                   # payload_write <file_path> <content>
  jq -n --arg p "$1" --arg c "$2" \
    '{session_id:"t",hook_event_name:"PreToolUse",tool_name:"Write",
      tool_input:{file_path:$p,content:$c}}'
}

payload_edit() {                    # payload_edit <file_path> <new_string>
  jq -n --arg p "$1" --arg s "$2" \
    '{session_id:"t",hook_event_name:"PreToolUse",tool_name:"Edit",
      tool_input:{file_path:$p,old_string:"old",new_string:$s}}'
}

# NotebookEdit names its target notebook_path, not file_path. A guard reading only file_path
# sees an empty target and lets the call through, which is what this builder is for.
payload_notebook() {                # payload_notebook <notebook_path> <source>
  jq -n --arg p "$1" --arg s "$2" \
    '{session_id:"t",hook_event_name:"PreToolUse",tool_name:"NotebookEdit",
      tool_input:{notebook_path:$p,new_source:$s}}'
}

# A hook must never exit anything but 0 (allow) or 2 (block). Claude Code treats every other
# code as a non-blocking error and runs the tool anyway, so a crash on unexpected input is a
# guard that silently stops guarding.
assert_exit_is_allow_or_block() {   # assert_exit_is_allow_or_block <rc>
  case "$1" in 0|2) return 0 ;; *) return 1 ;; esac
}

# assert_says <needle> <haystack>: substring test that needs no regex escaping.
assert_says() {
  case "$2" in *"$1"*) return 0 ;; *) return 1 ;; esac
}
