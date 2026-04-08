# normal-gpt

Make GPT talk like a normal person. No filler, no fluff, just the answer.

## What it does

A single system prompt that transforms GPT's verbose, corporate-sounding output into direct, informative responses. Tested on GPT-4o-mini with **93% reduction in output length** while preserving all useful information.

Before:
> "Great question! Python is a versatile, high-level programming language that has gained tremendous popularity in recent years. It's worth noting that Python was created by Guido van Rossum and first released in 1991..." (1500+ chars)

After:
> "A high-level interpreted language. Widely used for web dev, data science, ML, and scripting. Large standard library and package ecosystem." (200 chars)

## Usage

### OpenClaw (one command)

```bash
git clone https://github.com/hexie/normal-gpt.git && cd normal-gpt && bash install.sh
```

Uninstall:
```bash
bash install.sh --uninstall
```

The script auto-detects your `AGENTS.md` and injects the prompt. Start a new conversation to take effect.

### ChatGPT custom instructions

Copy the contents of `prompt.md` into ChatGPT's custom instructions field.

### Any OpenAI API tool

Copy the contents of `prompt.md` into the system prompt field of whatever tool you use (Cursor, Continue, your own app, etc.)

### API calls

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o-mini",
    "messages": [
      {"role": "system", "content": "<contents of prompt.md>"},
      {"role": "user", "content": "What is Python?"}
    ]
  }'
```

## Test results

10 prompts, GPT-4o-mini, temperature=0:

| # | Prompt | Original | normal-gpt | Reduction |
|---|--------|----------|-----------|-----------|
| 1 | What is 2+2? | 16 | 3 | 81% |
| 2 | What is Python? | 1584 | 213 | 87% |
| 3 | Explain how HTTP works | 3142 | 579 | 82% |
| 4 | Write hello world in Go | 621 | 191 | 69% |
| 5 | Is React better than Vue? | 2309 | 298 | 87% |
| 6 | 2+2等于几? | 18 | 14 | 22% |
| 7 | 什么是机器学习? | 1471 | 307 | 79% |
| 8 | 帮我写个排序算法 | 1139 | 553 | 51% |
| 9 | Redis和Memcached哪个好? | 1762 | 202 | 89% |
| 10 | Microservices pros/cons | 3083 | 631 | 80% |

## License

MIT
