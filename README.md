# normal-gpt

Make GPT talk like a normal person. No filler, no fluff, just the answer.

## What it does

A single system prompt that transforms GPT's verbose, corporate-sounding output into direct, informative responses. Tested on GPT-4o-mini (**80% reduction**) and GPT-5.4 (**55% reduction**) while preserving all useful information.

Before:
> "Python is a high-level, interpreted programming language known for its readability and simplicity. It was created by Guido van Rossum and first released in 1991. Python supports multiple programming paradigms, including procedural, object-oriented, and functional programming..." (1584 chars)

After:
> "A high-level interpreted programming language. It's widely used for web development, data science, machine learning, and scripting, featuring a large standard library and a rich ecosystem of third-party packages." (213 chars)

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

10 prompts, temperature=0. Measured in characters.

### GPT-4o-mini — average reduction: 80%

| # | Prompt | Original | normal-gpt | Reduction |
|---|--------|----------|-----------|-----------|
| 1 | What is 2+2? | 16 | 3 | 81% |
| 2 | What is Python? | 1584 | 213 | 86% |
| 3 | Explain how HTTP works | 3142 | 579 | 81% |
| 4 | Write hello world in Go | 621 | 191 | 69% |
| 5 | Is React better than Vue? | 2309 | 298 | 87% |
| 6 | 2+2等于几? | 18 | 14 | 22% |
| 7 | 什么是机器学习? | 1471 | 307 | 79% |
| 8 | 帮我写个排序算法 | 1139 | 553 | 51% |
| 9 | Redis和Memcached哪个好? | 1762 | 202 | 88% |
| 10 | Microservices pros/cons | 3083 | 631 | 79% |

### GPT-5.4 — average reduction: 55%

| # | Prompt | Original | normal-gpt | Reduction |
|---|--------|----------|-----------|-----------|
| 1 | What is 2+2? | 2 | 2 | 0% |
| 2 | What is Python? | 800 | 637 | 20% |
| 3 | Explain how HTTP works | 3875 | 1180 | 69% |
| 4 | Write hello world in Go | 87 | 126 | -44% |
| 5 | Is React better than Vue? | 1251 | 590 | 52% |
| 6 | 2+2等于几? | 14 | 2 | 85% |
| 7 | 什么是机器学习? | 1722 | 970 | 43% |
| 8 | 帮我写个排序算法 | 857 | 1308 | -52% |
| 9 | Redis和Memcached哪个好? | 3734 | 1417 | 62% |
| 10 | Microservices pros/cons | 4088 | 1084 | 73% |

GPT-5.4 is already more concise than 4o-mini out of the box. normal-gpt still helps significantly on verbose responses (#3, #5, #9, #10) but may add length to code answers (#4, #8) due to usage examples.

## License

MIT
