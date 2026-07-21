---
title: "Context Engineering: A Practical Guide for AI Agents (2026)"
source: "https://sourcegraph.com/blog/context-engineering-for-ai-agents"
author:
  - "[[Matt Tanner]]"
published: 2026-05-28
created: 2026-07-21
description: "How context engineering—curating exactly what AI agents see and know—is replacing prompt engineering as the core skill for building reliable AI systems."
tags:
  - "clippings"
draft: false
---

The shift from prompt engineering to context engineering represents the most important evolution in how we build AI applications in 2026. Prompts are still important — but the quality of what surrounds the prompt determines whether your agent succeeds.

## What Context Engineering Is

Context engineering is the discipline of deciding what information goes into an AI agent's context window at each step. It includes:

- The system prompt
- Retrieved documents (RAG)
- Conversation history
- Tool definitions and previous tool outputs
- User state and preferences
- Real-time data from external sources

Prompt engineering asks: *how should I phrase this?*  
Context engineering asks: *what should the agent know right now?*

## Why This Matters for Agents

Single-turn chatbots get away with good prompts. Agentic systems — which take actions, use tools, and run over multiple steps — fall apart without careful context management. The two failure modes:

1. **Too little context**: the agent lacks what it needs to act correctly
2. **Too much context**: the context window fills with noise, previous tool outputs, and conversation history that degrades performance (researchers call this "context rot")

## The Context Engineering Toolkit

### Retrieval-Augmented Generation (RAG)

Rather than loading an entire knowledge base into context, RAG retrieves only the relevant chunks for the current query. The quality of retrieval (not just the quality of the documents) determines quality of the response.

Good RAG requires:
- Clean, chunked source documents
- A reranker pass after initial retrieval (cuts noise dramatically)
- Metadata filtering to scope results by type, date, or source

### Context Summarization

As agents run multi-step tasks, their context fills with tool outputs and intermediate results. Summarization compresses old state into a shorter representation while preserving decisions and findings. Claude Code does this automatically — it summarizes prior conversation turns when approaching the context limit.

### Memory Systems

Short-term memory = the current context window.  
Long-term memory = a persistent store (vector DB, key-value store) that survives across sessions.

Designing what gets committed to long-term memory and what gets discarded is one of the hardest context engineering problems.

### Tool Definitions

Every tool you give an agent consumes tokens and attention. Research shows agents perform better with 15 focused, well-named tools than with 50 tools that overlap. Context engineer your tool loadout — give the agent what it needs for the current task, not everything it might ever need.

## Practical Patterns

**Pattern 1: Separate static and dynamic context**  
Static context (system rules, brand voice, business logic) goes at the top. Dynamic context (retrieved docs, user input, tool results) goes at the end. This enables prompt caching and leverages recency bias — the model attends strongly to what's most recent.

**Pattern 2: Context tiering**  
Tier 1 (always included): role, constraints, output format  
Tier 2 (session-scoped): user preferences, recent history  
Tier 3 (query-scoped): retrieved documents, tool results for this step

**Pattern 3: Progressive disclosure**  
Start with minimal context. Let the agent request more via tools if needed. This prevents context bloat from information the agent never uses.

## Common Mistakes

- Dumping entire documents into context instead of relevant chunks
- Keeping tool outputs in context long after they're needed
- Not summarizing multi-turn conversations before they exceed the window
- Using vague tool names that confuse the model about when to call them
- Forgetting that token cost scales linearly with context size

## The Measurement Challenge

Unlike prompts (where A/B testing is straightforward), context quality is hard to measure directly. Useful proxies:

- Task success rate across a test set
- Number of tool call errors per session
- Hallucination rate (claims not grounded in context)
- Average context tokens per completed task

The best context engineering teams treat this like infrastructure work — iterative, instrumented, and always tied to outcome metrics.
