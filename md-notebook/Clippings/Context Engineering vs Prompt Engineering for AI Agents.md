---
title: "Context Engineering vs Prompt Engineering for AI Agents"
source: "https://www.firecrawl.dev/blog/context-engineering"
author:
  - "[[Rafael Miller]]"
published: 2026-02-05
created: 2026-07-21
description: "Why context engineering—curating the exact information AI agents see—is the new meta-skill for production AI systems, and the research proving why bigger context windows alone don't help."
tags:
  - "clippings"
draft: false
---

The shift from prompt engineering to context engineering is the most important evolution in building AI agents. Here's what the research says and how to actually do it.

## The Core Distinction

**Prompt engineering**: crafting the wording of instructions.  
**Context engineering**: curating everything the model sees — system prompt, retrieved docs, history, tools, user state.

Andrej Karpathy: "Context engineering is the delicate art and science of filling the context window with just the right information for the next step."

Tobi Lutke (Shopify CEO): "the art of providing all the context for the task to be plausibly solvable by the LLM."

Prompt engineering gets you the first good output. Context engineering makes the 1,000th output just as good.

## The Research Case Against "Just Add More Context"

The intuition that bigger context windows solve context problems is wrong. Research proves it:

**"Lost in the Middle" (Stanford)**: LLMs perform best when key information is at the beginning or end of context. Information buried in the middle degrades performance significantly — regardless of total length.

**Context Rot (Chroma Research, 2025)**: Testing 18 frontier models including Claude 4 and GPT-4.1 showed accuracy degrades as context length grows, even on trivially simple tasks.

**Databricks Study**: Model correctness begins dropping around 32,000 tokens for Llama 3.1 405b — long before its context window fills.

**Pokémon Agent (Google Gemini team)**: Past 100k tokens, the agent stopped reasoning and started repeating past actions from its history.

**Sharded Prompts Study**: Splitting benchmark prompts across multiple conversation turns (like real conversations) caused an average 39% performance drop — because earlier wrong attempts stayed in context and poisoned reasoning.

## The Four Ways Context Fails

### 1. Context Poisoning
A hallucination or error enters context and gets repeatedly referenced. The Gemini Pokémon agent hallucinated game state, developed strategies based on impossible objectives, and couldn't escape the loop.

**Fix**: Context validation before committing to memory. Separate context threads for different information types.

### 2. Context Distraction
Context grows so large the model over-attends to accumulated history instead of reasoning from first principles.

**Fix**: Compaction and summarization. Compress prior turns while preserving key decisions.

### 3. Context Confusion
Superfluous content influences the response even when irrelevant. Berkeley Function-Calling Leaderboard data: every model performs worse with more tools. A quantized Llama 3.1 8b failed with 46 tools in context; succeeded with 19.

**Fix**: Apply RAG to tool selection. Keep active tools under 30.

### 4. Context Clash
Different parts of context contradict each other. Common with MCP tools whose descriptions conflict with your system prompt.

**Fix**: Context pruning. Remove outdated or conflicting information as new facts arrive.

## Practical Techniques

### Separate Static and Dynamic Context

**Static context** (system rules, brand voice, available tools) → beginning of prompt → enables prompt caching, saves up to 90% of token costs.

**Dynamic context** (retrieved docs, user state, tool results) → end of prompt → leverages recency bias.

### Just-In-Time Retrieval

Instead of loading all possibly-relevant data at session start, give the agent tools to fetch what it needs. The ReAct pattern: reason about what's needed → act to retrieve it → reason again with new context.

More LLM calls, but dramatically higher accuracy on complex tasks.

### Tool Loadout Management

Research shows 3× better tool selection accuracy when you:
- Use RAG to select which tools to give the agent for the current task
- Keep active tools under 30
- Write tool descriptions that clearly separate when each should be used

### Context Compaction for Long Tasks

For multi-hour tasks, context compaction works by:
1. Passing message history to the model for summarization
2. Preserving architectural decisions, unresolved bugs, implementation details
3. Discarding redundant tool outputs and intermediate reasoning
4. Continuing with compressed context + recently accessed files

Claude Code does this automatically when approaching context limits.

## What This Means for AI App Builders

The agents that will dominate in 2026 aren't the ones running the largest models or with the most context tokens. They're the ones with the most carefully engineered context pipelines:

- Retrieve the minimum relevant information, not everything
- Summarize aggressively as sessions grow
- Match tool availability to the current task step
- Keep static and dynamic context separated and clean

The models are already good enough. The context pipeline is where the performance gap lives.
