#!/usr/bin/env bash
# run-tests.sh — Re-run the talk-normal benchmark against GPT models.
#
# Usage:
#   OPENAI_API_KEY=sk-xxx bash scripts/run-tests.sh
#
# Runs 10 standard prompts against two models (gpt-5.4, gpt-4o-mini), each with:
#   1. No system prompt (baseline "Original")
#   2. prompt.md as system prompt ("talk-normal")
#
# Outputs: TEST_RESULTS.md with summary table + full responses.
# All calls use temperature=0 for reproducibility.
#
# Requirements: curl, jq
# Compatible with bash 3.2+ (no associative arrays).
set -euo pipefail

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "Error: OPENAI_API_KEY is not set." >&2
  echo "Usage: OPENAI_API_KEY=sk-xxx bash scripts/run-tests.sh" >&2
  exit 1
fi

for cmd in curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is required but not installed." >&2; exit 1; }
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPT_FILE="$REPO_ROOT/prompt.md"
OUTPUT_FILE="$REPO_ROOT/TEST_RESULTS.md"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: prompt.md not found at $PROMPT_FILE" >&2
  exit 1
fi

SYSTEM_PROMPT=$(cat "$PROMPT_FILE")
VERSION=$(head -1 "$PROMPT_FILE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
VERSION="${VERSION:-unknown}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

API_URL="https://api.openai.com/v1/chat/completions"

# Call OpenAI API and return the assistant message content.
# Args: $1=model, $2=user_prompt, $3=system_prompt (empty string = no system prompt)
call_api() {
  local model="$1"
  local user_prompt="$2"
  local sys_prompt="$3"

  local user_json
  user_json=$(printf '%s' "$user_prompt" | jq -Rs .)
  local sys_json
  sys_json=$(printf '%s' "$sys_prompt" | jq -Rs .)

  local body
  if [ -n "$sys_prompt" ]; then
    body="{\"model\":\"$model\",\"messages\":[{\"role\":\"system\",\"content\":$sys_json},{\"role\":\"user\",\"content\":$user_json}],\"temperature\":0}"
  else
    body="{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":$user_json}],\"temperature\":0}"
  fi

  local response
  response=$(curl -s -X POST "$API_URL" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$body" \
    --max-time 120)

  local content
  content=$(printf '%s' "$response" | jq -r '.choices[0].message.content // empty')

  if [ -z "$content" ]; then
    local error
    error=$(printf '%s' "$response" | jq -r '.error.message // "unknown error"')
    echo "[API Error: $error]"
    echo "API_ERROR($model): $error" >&2
    return 0
  fi

  printf '%s' "$content"
}

echo "talk-normal benchmark — v$VERSION"
echo "================================"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Models: gpt-5.4, gpt-4o-mini"
echo "Temperature: 0"
echo "Prompts: 10"
echo ""

# The 10 standard prompts
set -- \
  "What is the difference between TCP and UDP?" \
  "What is Python?" \
  "Explain how HTTP works" \
  "How does DNS work?" \
  "Is React better than Vue?" \
  "Docker和虚拟机有什么区别?" \
  "什么是机器学习?" \
  "什么是区块链?" \
  "Redis和Memcached哪个好?" \
  "What are the pros and cons of microservices?"

PROMPT_COUNT=$#

# Pass 1: Run all API calls, save responses and char counts to files
for model in gpt-5.4 gpt-4o-mini; do
  echo "=== Testing model: $model ==="
  echo ""

  num=0
  for prompt in "$@"; do
    num=$((num + 1))
    echo "  [$num/$PROMPT_COUNT] $prompt"

    # Original (no system prompt)
    printf "    Original... "
    orig=$(call_api "$model" "$prompt" "")
    printf '%s' "$orig" > "$TMPDIR/${model}-${num}-orig.txt"
    orig_len=$(printf '%s' "$orig" | wc -m | tr -d ' ')
    echo "$orig_len" > "$TMPDIR/${model}-${num}-orig-len.txt"
    echo "$orig_len chars"

    sleep 1

    # talk-normal (with system prompt)
    printf "    talk-normal... "
    tn=$(call_api "$model" "$prompt" "$SYSTEM_PROMPT")
    printf '%s' "$tn" > "$TMPDIR/${model}-${num}-tn.txt"
    tn_len=$(printf '%s' "$tn" | wc -m | tr -d ' ')
    echo "$tn_len" > "$TMPDIR/${model}-${num}-tn-len.txt"
    echo "$tn_len chars"

    sleep 1
  done

  echo ""
done

# Pass 2: Generate TEST_RESULTS.md
echo "=== Generating TEST_RESULTS.md ==="

{
  echo "# talk-normal Test Results — Full Comparison"
  echo ""
  echo "All tests run with \`temperature=0\`. Measured in characters."
  echo "Prompt version: v$VERSION ($(date +%Y-%m-%d))"
  echo ""
  echo "Two responses per question:"
  echo "- **Original** — GPT with no system prompt (the verbose default)"
  echo "- **talk-normal** — GPT with the talk-normal system prompt"
  echo ""
  echo "## Summary"
  echo ""

  for model in gpt-5.4 gpt-4o-mini; do
    safe_model=$(echo "$model" | tr '.' '-')
    echo "### ${model}"
    echo ""
    echo "| # | Prompt | Original | talk-normal | Reduction |"
    echo "|---|--------|----------|-----------|-----------|"

    total_orig=0
    total_tn=0
    num=0

    for prompt in "$@"; do
      num=$((num + 1))
      orig_len=$(cat "$TMPDIR/${model}-${num}-orig-len.txt")
      tn_len=$(cat "$TMPDIR/${model}-${num}-tn-len.txt")

      if [ "$orig_len" -gt 0 ] 2>/dev/null; then
        reduction=$(( (orig_len - tn_len) * 100 / orig_len ))
      else
        reduction=0
      fi

      echo "| $num | $prompt | $orig_len | $tn_len | ${reduction}% |"

      total_orig=$((total_orig + orig_len))
      total_tn=$((total_tn + tn_len))
    done

    if [ "$total_orig" -gt 0 ]; then
      avg_reduction=$(( (total_orig - total_tn) * 100 / total_orig ))
    else
      avg_reduction=0
    fi

    echo ""
    echo "**Average reduction: ${avg_reduction}%**"
    echo ""
  done

  echo "---"
  echo ""
  echo "## Full Responses"
  echo ""

  num=0
  for prompt in "$@"; do
    num=$((num + 1))
    echo "### #${num}: ${prompt}"
    echo ""

    for model in gpt-5.4 gpt-4o-mini; do
      orig_len=$(cat "$TMPDIR/${model}-${num}-orig-len.txt")
      tn_len=$(cat "$TMPDIR/${model}-${num}-tn-len.txt")

      echo "#### $model"
      echo ""
      echo "<details>"
      echo "<summary>Original ($orig_len chars)</summary>"
      echo ""
      cat "$TMPDIR/${model}-${num}-orig.txt"
      echo ""
      echo ""
      echo "</details>"
      echo ""
      echo "After ($tn_len chars):"
      echo ""
      cat "$TMPDIR/${model}-${num}-tn.txt"
      echo ""
      echo ""
    done
  done

} > "$OUTPUT_FILE"

echo "Written to $OUTPUT_FILE"
echo ""
echo "=== Summary ==="
for model in gpt-5.4 gpt-4o-mini; do
  total_orig=0
  total_tn=0
  num=0
  for prompt in "$@"; do
    num=$((num + 1))
    o=$(cat "$TMPDIR/${model}-${num}-orig-len.txt")
    t=$(cat "$TMPDIR/${model}-${num}-tn-len.txt")
    total_orig=$((total_orig + o))
    total_tn=$((total_tn + t))
  done
  avg=$(( (total_orig - total_tn) * 100 / total_orig ))
  echo "  $model: avg ${avg}% reduction"
done
echo ""
echo "Done. Review TEST_RESULTS.md, then commit if the results look right."
