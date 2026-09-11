#!/usr/bin/env bash
# Pi statusline — llama-server token-per-second metrics
# Color palette: Rose Pine / VSCode dark (same as claude statusline)
#   pine   #31748f   blue-teal  (model name, section labels)
#   gold   #f6c177   warm amber (prompt TPS)
#   rose   #eb6f92   pink-red   (generation TPS)
#   foam   #9ccfd8   cyan       (context bar)
#   green  #93c795              (good TPS ≥30)
#   muted  #6e6a86              (separators, secondary labels)
# Icons: prompt TPS, gen TPS

# ── llama-server config ──────────────────────────────────────────────────────
LLAMA_URL="${LLAMA_SERVER_URL:-http://192.168.1.185:8081}"

# ── helpers ─────────────────────────────────────────────────────────────────
c() { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
reset='\033[0m'
bold='\033[1m'
dim='\033[2m'

pine=$(c 49 116 143)
gold=$(c 246 193 119)
rose=$(c 235 111 146)
foam=$(c 156 207 216)
green=$(c 147 199 149)
muted=$(c 110 106 134)
sep="${muted}│${reset}"

# ── auth ─────────────────────────────────────────────────────────────────────
_auth_key=""
_auth_file="${PI_AUTH_FILE:-${HOME}/.pi/agent/auth.json}"
if [[ -f "$_auth_file" ]]; then
  _auth_key=$(jq -r '.["llama-server"].key // empty' "$_auth_file" 2>/dev/null)
fi

# ── fetch llama-server metrics ───────────────────────────────────────────────
fetch_metrics() {
  # Build curl args as an array so quotes don't get mangled
  local -a curl_args=("-s" "--max-time" "2")
  [[ -n "$_auth_key" ]] && curl_args+=("-H" "Authorization: Bearer $_auth_key")

  # Try Prometheus text format first, fall back to JSON
  local metrics
  metrics=$(curl "${curl_args[@]}" "${LLAMA_URL}/metrics" 2>/dev/null)
  if [[ -z "$metrics" || "$metrics" == *"error"* ]]; then
    metrics=$(curl "${curl_args[@]}" "${LLAMA_URL}/metrics?format=json" 2>/dev/null)
    if [[ -n "$metrics" ]]; then
      # JSON format: convert to key=value pairs
      echo "$metrics" | jq -r 'to_entries[] | "\(.key)=\(.value)"' 2>/dev/null
      return
    fi
  fi
  echo "$metrics"
}

# Parse a single metric value from Prometheus-style text output.
# Handles metric names with colons (llama.cpp naming) and Prometheus labels.
# macOS-compatible: uses grep -E + awk instead of grep -oP.
_get_metric() {
  local name="$1"
  # Escape colons for regex
  local escaped_name
  escaped_name=$(echo "$name" | sed 's/:/\\:/g')
  echo "$_metrics" \
    | grep -E "^${escaped_name}(\{[^}]*\})?[[:space:]]" 2>/dev/null \
    | head -1 \
    | awk '{print $NF}' \
    || echo "0"
}

_metrics=$(fetch_metrics)

# ── extract llama.cpp metrics ────────────────────────────────────────────────
# Gauge metrics from llama.cpp Prometheus endpoint
prompt_tps=$(_get_metric "llamacpp:prompt_tokens_seconds")
gen_tps=$(_get_metric "llamacpp:predicted_tokens_seconds")

# ── format TPS with color ────────────────────────────────────────────────────
fmt_tps() {
  local val="${1:-0}"
  # Color: green ≥ 30, gold ≥ 10, muted < 10
  local color="$muted"
  if awk -v v="$val" 'BEGIN { exit (v >= 30) ? 0 : 1 }'; then
    color="$green"
  elif awk -v v="$val" 'BEGIN { exit (v >= 10) ? 0 : 1 }'; then
    color="$gold"
  fi
  if awk -v v="$val" 'BEGIN { exit (v > 0) ? 0 : 1 }'; then
    printf "%s%.0f${reset} t/s" "$color" "$val"
  else
    printf "%s—${reset}" "$color"
  fi
}

# ── format token counts (k / M) ──────────────────────────────────────────────
fmt_tok() {
  local n="${1:-0}"
  awk -v n="$n" 'BEGIN {
    if (n >= 1000000)     printf "%.1fM", n/1000000
    else if (n >= 1000)   printf "%.1fk", n/1000
    else                  printf "%d", n
  }'
}

# ── model display from stdin (same as claude script) ─────────────────────────
input=$(cat)

_jq() { echo "$input" | jq -r "$1 // empty" 2>/dev/null; }

model_id=$(_jq '.model.id')
model_name=$(_jq '.model.display_name')
cwd=$(_jq '.workspace.current_dir')
[[ -z "$cwd" ]] && cwd=$(_jq '.cwd')
used_pct=$(_jq '.context_window.used_percentage')
remaining_pct=$(_jq '.context_window.remaining_percentage')
ctx_size=$(_jq '.context_window.context_window_size')
total_in=$(_jq '.context_window.total_input_tokens')
total_out=$(_jq '.context_window.total_output_tokens')
cur_in=$(_jq '.context_window.current_usage.input_tokens')
cur_out=$(_jq '.context_window.current_usage.output_tokens')
cache_write=$(_jq '.context_window.current_usage.cache_creation_input_tokens')
cache_read=$(_jq '.context_window.current_usage.cache_read_input_tokens')
repo_owner=$(_jq '.workspace.repo.owner')
repo_name=$(_jq '.workspace.repo.name')
branch=$(_jq '.workspace.git_worktree')

# ── context bar (12 chars wide) ──────────────────────────────────────────────
ctx_bar=""
if [[ -n "$used_pct" ]]; then
  pct_int=$(printf '%.0f' "$used_pct")
  bar_width=12
  filled=$(( pct_int * bar_width / 100 ))
  empty=$(( bar_width - filled ))
  if   (( pct_int >= 80 )); then bar_color="$rose"
  elif (( pct_int >= 60 )); then bar_color="$gold"
  else                            bar_color="$green"
  fi
  bar="${bar_color}"
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  bar+="${muted}"
  for (( i=0; i<empty; i++ )); do  bar+="░"; done
  bar+="${reset}"
  ctx_bar="${bar} ${bar_color}${pct_int}%${reset}"
fi

# ── cache hit ratio ──────────────────────────────────────────────────────────
cache_hit=""
if [[ -n "$cache_read" || -n "$cache_write" || -n "$cur_in" ]]; then
  cr=${cache_read:-0}; cw=${cache_write:-0}; ci=${cur_in:-0}
  denom=$(( cr + cw + ci ))
  if (( denom > 0 )); then
    hit=$(( cr * 100 / denom ))
    if   (( hit >= 80 )); then hit_color="$green"
    elif (( hit >= 50 )); then hit_color="$gold"
    else                        hit_color="$rose"
    fi
    cache_hit="${hit_color}${hit}%${reset}"
  fi
fi

# ── model display (shorten) ──────────────────────────────────────────────────
short_model=""
if [[ -n "$model_name" ]]; then
  short_model="${model_name#Claude }"
fi

# ── repo / branch ─────────────────────────────────────────────────────────────
repo_str=""
if [[ -n "$repo_owner" && -n "$repo_name" ]]; then
  repo_str="${muted} ${reset}${repo_owner}/${repo_name}"
fi
if [[ -n "$branch" ]]; then
  repo_str+=" ${muted} ${reset}${branch}"
fi

# ── assemble ─────────────────────────────────────────────────────────────────
out=""

if [[ -n "$short_model" ]]; then
  out+="${pine}${bold} ${short_model}${reset}"
fi

if [[ -n "$repo_str" ]]; then
  out+=" ${sep} ${repo_str}"
fi

if [[ -n "$ctx_bar" ]]; then
  out+=" ${sep} ${foam} ctx${reset} ${ctx_bar}"
fi

if [[ -n "$cur_in" || -n "$cur_out" ]]; then
  out+=" ${sep} ${foam}$(fmt_tok "${total_in:-0}")${reset}${muted}in${reset}"
  out+=" ${muted}/${reset}${rose}$(fmt_tok "${total_out:-0}")${reset}${muted}out${reset}"
fi

if [[ -n "$cache_write" || -n "$cache_read" ]]; then
  cw_str=$(fmt_tok "${cache_write:-0}")
  cr_str=$(fmt_tok "${cache_read:-0}")
  out+=" ${sep} ${gold}↑${cw_str}${reset}${muted}w${reset} ${green}↓${cr_str}${reset}${muted}r${reset}"
  [[ -n "$cache_hit" ]] && out+=" ${muted}${reset}${cache_hit}"
fi

# ── llama-server TPS metrics ─────────────────────────────────────────────────
if [[ -n "$prompt_tps" && "$prompt_tps" != "0" ]] || [[ -n "$gen_tps" && "$gen_tps" != "0" ]]; then
  out+=" ${sep} ${gold}prompt $(fmt_tps "$prompt_tps")${reset}"
  out+=" ${sep} ${rose}gen $(fmt_tps "$gen_tps")${reset}"
fi

printf "%b\n" "$out"
