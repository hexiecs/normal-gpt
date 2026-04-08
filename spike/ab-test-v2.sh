#!/usr/bin/env bash
# A/B test v2: compare GPT with tuned system prompt vs Opus baseline
# Usage: OPENAI_API_KEY=xxx bash spike/ab-test-v2.sh
set -euo pipefail

API_KEY="${OPENAI_API_KEY:?Set OPENAI_API_KEY}"
MODEL="gpt-4o-mini"

# v1 prompt: too aggressive, strips useful information
PROMPT_V1='You are direct and concise. Follow these rules strictly:
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

# v2 prompt: balanced, matches Opus style — direct but informative
PROMPT_V2='Be direct and informative. No filler, no fluff, but give enough information to actually be useful.

Rules:
- Lead with the answer, then add context if it helps
- Kill all filler phrases: "I'\''d be happy to", "Great question", "It'\''s worth noting", "Certainly", "Of course", "Let me break this down", "首先我们需要", "值得注意的是", "综上所述", "让我们一起来看看"
- Never restate the user'\''s question
- Yes/no questions: answer first, explain briefly if needed
- Comparisons: state your recommendation with reasoning, not a balanced essay
- Code: give the code, add usage example or complexity note if non-trivial. Skip "Certainly! Here is..."
- Explanations: cover the key points concisely. Use structure (numbered steps, short bullets) when it aids clarity, not as decoration
- Match response depth to question complexity. "What is 2+2" gets one word. "How does HTTP work" gets a paragraph with the key steps.
- End with a concrete recommendation or next step when relevant, not a generic summary
- No "In conclusion", "In summary", "Hope this helps"

Calibration examples:

User: What is Python?
BAD: "Great question! Python is a versatile, high-level programming language that has gained tremendous popularity..."
BAD (too short): "A programming language."
GOOD: "A high-level interpreted language. Widely used for web dev, data science, ML, and scripting. Large ecosystem of third-party packages."

User: Redis和Memcached哪个好?
BAD: [500字对比文章]
BAD (too short): "Redis更好。"
GOOD: "大多数场景选Redis。支持更多数据结构、可持久化、有集群方案。Memcached在纯key-value缓存场景下更轻量，但功能少。新项目默认Redis。"'

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

OUTDIR="/tmp/normal-gpt-v2-$(date +%s)"
mkdir -p "$OUTDIR"

echo "=== A/B Test v2: GPT prompt v1 vs v2 ==="
echo "Model: $MODEL"
echo "Output: $OUTDIR"
echo ""

for i in "${!PROMPTS[@]}"; do
  idx=$((i+1))
  prompt="${PROMPTS[$i]}"
  echo "--- Prompt $idx: $prompt ---"

  echo "  [V1] Aggressive prompt..."
  resp_v1=$(call_gpt "$PROMPT_V1" "$prompt")
  echo "$resp_v1" > "$OUTDIR/${idx}-V1.txt"

  echo "  [V2] Balanced prompt..."
  resp_v2=$(call_gpt "$PROMPT_V2" "$prompt")
  echo "$resp_v2" > "$OUTDIR/${idx}-V2.txt"

  echo "  V1: ${#resp_v1} chars | V2: ${#resp_v2} chars"
  echo ""
done

# Print all V2 responses
echo ""
echo "=== V2 Responses (balanced prompt) ==="
for i in "${!PROMPTS[@]}"; do
  idx=$((i+1))
  echo ""
  echo "--- #$idx: ${PROMPTS[$i]} ---"
  cat "$OUTDIR/${idx}-V2.txt"
  echo ""
done

# Summary table
echo ""
echo "=== Summary ==="
printf "%-4s %-45s %8s %8s\n" "#" "Prompt" "V1" "V2"
echo "---- --------------------------------------------- -------- --------"
total_v1=0
total_v2=0
for i in "${!PROMPTS[@]}"; do
  idx=$((i+1))
  len_v1=$(wc -c < "$OUTDIR/${idx}-V1.txt" | tr -d ' ')
  len_v2=$(wc -c < "$OUTDIR/${idx}-V2.txt" | tr -d ' ')
  total_v1=$((total_v1 + len_v1))
  total_v2=$((total_v2 + len_v2))
  short="${PROMPTS[$i]}"
  [ ${#short} -gt 43 ] && short="${short:0:40}..."
  printf "%-4s %-45s %8s %8s\n" "$idx" "$short" "$len_v1" "$len_v2"
done
echo "---- --------------------------------------------- -------- --------"
printf "%-4s %-45s %8s %8s\n" "" "TOTAL" "$total_v1" "$total_v2"
