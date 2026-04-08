#!/usr/bin/env bash
# A/B test: compare GPT output with and without conciseness system prompt
# Usage: OPENAI_API_KEY=xxx bash spike/ab-test.sh
set -euo pipefail

API_KEY="${OPENAI_API_KEY:?Set OPENAI_API_KEY}"
MODEL="gpt-4o-mini"

SYSTEM_PROMPT='You are direct and concise. Follow these rules strictly:
- Lead with the answer, not the reasoning
- Simple questions get 1-2 sentences max
- No filler phrases: "I'\''d be happy to", "Great question", "It'\''s worth noting", "Certainly", "Of course", "Let me break this down"
- No bullet points unless the user explicitly asks for a list
- No restating the user'\''s question
- No hedging: "It depends" must be followed by the actual answer
- Code answers: just the code, explain only if non-obvious
- If you can say it in one sentence, use one sentence
- No Chinese filler: "首先我们需要", "值得注意的是", "综上所述", "总而言之", "需要注意的是", "让我们一起来看看"

Examples of BAD vs GOOD:
User: What is Python?
BAD: "Great question! Python is a versatile, high-level programming language..."
GOOD: "A high-level programming language. Popular for web, data science, scripting."

User: 2+2等于几?
BAD: "好的，让我来帮你解答这个问题。2+2的结果是4。"
GOOD: "4。"'

PROMPTS=(
  "What is 2+2?"
  "What is Python?"
  "Explain how HTTP works"
  "Write a hello world in Go"
  "Is React better than Vue?"
  "2+2等于几?"
  "什么是机器学习?"
  "帮我写个排序算法"
  "Redis和Memcached哪个好?"
  "What are the pros and cons of microservices?"
)

call_gpt() {
  local system="$1"
  local user="$2"
  local body

  if [ -z "$system" ]; then
    body=$(jq -n --arg model "$MODEL" --arg user "$user" \
      '{model: $model, messages: [{role: "user", content: $user}], temperature: 0}')
  else
    body=$(jq -n --arg model "$MODEL" --arg system "$system" --arg user "$user" \
      '{model: $model, messages: [{role: "system", content: $system}, {role: "user", content: $user}], temperature: 0}')
  fi

  curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$body" | jq -r '.choices[0].message.content // "ERROR"'
}

OUTDIR="/tmp/normal-gpt-ab-$(date +%s)"
mkdir -p "$OUTDIR"

echo "=== A/B Test: GPT without vs with system prompt ==="
echo "Model: $MODEL"
echo "Output: $OUTDIR"
echo ""

for i in "${!PROMPTS[@]}"; do
  idx=$((i+1))
  prompt="${PROMPTS[$i]}"
  echo "--- Prompt $idx: $prompt ---"

  echo "  [A] No system prompt..."
  resp_a=$(call_gpt "" "$prompt")
  echo "$resp_a" > "$OUTDIR/${idx}-A.txt"
  len_a=${#resp_a}

  echo "  [B] With system prompt..."
  resp_b=$(call_gpt "$SYSTEM_PROMPT" "$prompt")
  echo "$resp_b" > "$OUTDIR/${idx}-B.txt"
  len_b=${#resp_b}

  ratio=0
  if [ "$len_a" -gt 0 ]; then
    ratio=$(( (len_a - len_b) * 100 / len_a ))
  fi

  echo "  A: ${len_a} chars | B: ${len_b} chars | reduction: ${ratio}%"
  echo ""
done

# Summary
echo "=== Summary ==="
echo ""
printf "%-4s %-45s %8s %8s %8s\n" "#" "Prompt" "A(chars)" "B(chars)" "Reduce%"
echo "---- --------------------------------------------- -------- -------- --------"

total_a=0
total_b=0
for i in "${!PROMPTS[@]}"; do
  idx=$((i+1))
  len_a=$(wc -c < "$OUTDIR/${idx}-A.txt" | tr -d ' ')
  len_b=$(wc -c < "$OUTDIR/${idx}-B.txt" | tr -d ' ')
  total_a=$((total_a + len_a))
  total_b=$((total_b + len_b))
  ratio=0
  [ "$len_a" -gt 0 ] && ratio=$(( (len_a - len_b) * 100 / len_a ))
  short_prompt="${PROMPTS[$i]}"
  [ ${#short_prompt} -gt 43 ] && short_prompt="${short_prompt:0:40}..."
  printf "%-4s %-45s %8s %8s %7s%%\n" "$idx" "$short_prompt" "$len_a" "$len_b" "$ratio"
done

total_ratio=0
[ "$total_a" -gt 0 ] && total_ratio=$(( (total_a - total_b) * 100 / total_a ))
echo "---- --------------------------------------------- -------- -------- --------"
printf "%-4s %-45s %8s %8s %7s%%\n" "" "TOTAL" "$total_a" "$total_b" "$total_ratio"
echo ""
echo "Full responses saved in: $OUTDIR"
