---
name: tv-mcp-failure-driven-sync
description: Classify TradingView MCP failures by layer, check whether upstream tradesdontlie/tradingview-mcp main already addresses the failed area, and decide whether to keep, retire, test, or create a minimal local fork patch. Use when the user asks whether a TradingView MCP patch is still needed, whether upstream fixed a failure, to compare upstream and fork changes, or to run failure-driven upstream sync/self-healing for TradingView MCP.
---

# TV MCP Failure-driven Sync

## Purpose

Use this skill when TradingView MCP fails and we need to decide whether to:

- keep the local fork patch
- check upstream main
- test upstream in a separate worktree
- adopt upstream changes
- create a minimal local patch
- stop and wait for upstream

Treat `origin` (`https://github.com/tradesdontlie/tradingview-mcp.git`) as upstream and `fork` (`https://github.com/kakakoi/tradingview-mcp-1.git`) as the personal fork. Do not push to `origin`.

## Triggers

Use this skill when the user says:

- TV MCPが壊れた
- Strategy Tester extraction bug
- metric_count: 0
- metrics: {}
- data_get_strategy_results returned empty metrics
- data_get_strategy_results returned No strategy found
- Strategy Tester UI has values but MCP returned empty metrics
- 本家で直っているか確認して
- このpatchまだ必要？
- 本家更新を見て
- upstreamと比較して
- TradingView MCP failure-driven sync
- MCPの自浄作用を回して

## Default Mode

Use `consult` by default. Use `ops-finalize` only when the user explicitly asks to record, commit, or push documentation or policy changes. Use a separate `tv-validate` prompt for any TradingView smoke.

## Workflow

1. Classify the failed layer:
   - CDP
   - MCP route
   - chart context
   - Pine Editor
   - Pine source reflection
   - compile/save
   - add-to-chart
   - study recognition
   - Strategy Tester recognition
   - metrics extraction
   - Strategy Tester extraction bug
2. Do not patch immediately.
3. Check current local state:
   - branch
   - remotes
   - status
   - commits ahead of `origin/main`
   - current fork branch, if available
4. Fetch upstream only when needed.
   - Do not pull.
   - Do not merge.
   - Do not rebase.
   - Do not cherry-pick.
   - Do not reset.
5. Check whether upstream touched relevant files:
   - `src/core/pine.js`
   - `src/tools/pine.js`
   - `src/core/data.js`
   - `src/tools/data.js`
   - `src/core/ui.js`
   - `src/connection.js`
   - `src/core/tab.js`
6. Compare upstream with the local patch:
   - Does upstream already solve the failed layer?
   - Does upstream conflict with the local patch?
   - Is the local patch still needed?
   - Is the local patch now obsolete?
   - Is a separate worktree smoke needed?
7. Decide status:
   - `patch-still-needed`
   - `patch-obsolete`
   - `upstream-likely-fixes`
   - `upstream-unknown-test-needed`
   - `needs-local-minimal-patch`
   - `blocked-wait-for-upstream`
   - `needs-user-choice`
8. Recommend one next action only.

## Repository Rules

- Use `tradingview-public-49222` as the canonical MCP route.
- Use `127.0.0.1:49222` as the canonical CDP endpoint.
- Treat `C:\tv-mcp-public-test` as the stable local repo.
- Use `C:\tv-mcp-upstream-test` for optional upstream smoke in a separate worktree.
- Treat `tradingview-mcp-pine-editor-fix` as the personal fork branch.
- Push only to `fork`, normally with `git push fork HEAD:tradingview-mcp-pine-editor-fix`, and only when explicitly asked.

## Hard Prohibitions

- Do not push to upstream.
- Do not push to `origin`.
- Do not force push.
- Do not run `git pull`.
- Do not merge.
- Do not rebase.
- Do not cherry-pick.
- Do not reset.
- Do not edit files unless explicitly asked.
- Do not run TradingView MCP in `consult` mode.
- Do not run Pine reflection, compile, add-to-chart, or Strategy Tester metrics during upstream comparison.
- Do not stage unrelated files.
- Do not use `git add .` or `git add -A`.
- Do not print Pine source.
- Do not expose secrets, tokens, cookies, localStorage, or account data.
- Do not enable automatic pull/update on MCP startup.
- Do not stage `package-lock.json` unless the task explicitly targets dependency changes.
- Do not change `src/core/pine.js`, `src/tools/pine.js`, `src/connection.js`, `src/core/tab.js`, or `start-tv-49222.ps1` during consult-mode upstream comparison.

## Output

```md
## Mode

## Failed layer

## Local state

## Upstream changes

## Relevant files changed upstream

## Does upstream cover local patch?

## Patch status

## Risk

## One next action
```
