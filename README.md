# normal-gpt

Make GPT talk like a normal person. No filler, no fluff, just the answer.

## What it does

A single system prompt that transforms GPT's verbose, corporate-sounding output into direct, informative responses. Tested on GPT-4o-mini (**74% reduction**) and GPT-5.4 (**55% reduction**) while preserving all useful information.

Before (GPT-4o-mini, 1525 chars):
> "Python is a high-level, interpreted programming language known for its readability and simplicity. It was created by Guido van Rossum and first released in 1991. Python supports multiple programming paradigms, including procedural, object-oriented, and functional programming..." (+ 6 bullet points)

After (GPT-4o-mini, 469 chars):
> "Python is a high-level, interpreted programming language known for its readability and versatility. It supports multiple programming paradigms, including procedural, object-oriented, and functional programming. Python is widely used in web development, data analysis, artificial intelligence, scientific computing, and automation due to its extensive libraries and frameworks. Its simplicity makes it an excellent choice for beginners and experienced developers alike."

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

### GPT-4o-mini — average reduction: 74%

| # | Prompt | Original | normal-gpt | Reduction |
|---|--------|----------|-----------|-----------|
| 1 | TCP vs UDP? | 2561 | 831 | 67% |
| 2 | What is Python? | 1525 | 469 | 69% |
| 3 | Explain how HTTP works | 3783 | 927 | 75% |
| 4 | How does DNS work? | 3160 | 1039 | 67% |
| 5 | Is React better than Vue? | 2386 | 313 | 86% |
| 6 | 2+2等于几? | 18 | 14 | 22% |
| 7 | 什么是机器学习? | 1471 | 572 | 61% |
| 8 | 什么是区块链? | 440 | 209 | 52% |
| 9 | Redis和Memcached哪个好? | 1898 | 372 | 80% |
| 10 | Microservices pros/cons | 3111 | 687 | 77% |

### GPT-5.4 — average reduction: 55%

| # | Prompt | Original | normal-gpt | Reduction |
|---|--------|----------|-----------|-----------|
| 1 | TCP vs UDP? | 1039 | 595 | 42% |
| 2 | What is Python? | 662 | 452 | 31% |
| 3 | Explain how HTTP works | 4856 | 1686 | 65% |
| 4 | How does DNS work? | 3258 | 1574 | 51% |
| 5 | Is React better than Vue? | 1201 | 661 | 44% |
| 6 | 2+2等于几? | 14 | 2 | 85% |
| 7 | 什么是机器学习? | 2245 | 885 | 60% |
| 8 | 什么是区块链? | 613 | 339 | 44% |
| 9 | Redis和Memcached哪个好? | 3143 | 1015 | 67% |
| 10 | Microservices pros/cons | 3635 | 1418 | 60% |

GPT-5.4 is already more concise than 4o-mini out of the box. normal-gpt still cuts verbose responses by 44-85% on both models.

## License

MIT
