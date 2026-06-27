# AGENTS.md

This repository is the local TradingView MCP harness used from Codex.

## Canonical TradingView route

- Use only `tradingview-public-49222`.
- Use only CDP `127.0.0.1:49222`.
- Do not use legacy `tradingview`, `tv_launch`, or `9222`.
- For freshly spawned local MCP smoke processes, set:
  - `TV_CDP_HOST=127.0.0.1`
  - `TV_CDP_PORT=49222`

## Work modes

- In `consult`, do not edit files, run TradingView MCP tools, reflect Pine source, compile, add to chart, fetch Strategy Tester metrics, pull, merge, rebase, cherry-pick, reset, commit, or push.
- In `tv-validate`, run only the explicitly requested validation layer and stop after the first clear result.
- In `ops-finalize`, record, stage, commit, or push only when explicitly requested.

## Strategy Tester extraction failures

If `data_get_strategy_results` returns `success: true` with `metric_count: 0` or `metrics: {}`, classify it as `Strategy Tester extraction bug` when the strategy is visible or Strategy Tester UI recognizes it.

Do not immediately inspect or patch local MCP source.

Route as follows:

1. `tv-strategy-tester-capture` records the failed capture and evidence classification.
2. Next action is `tv-mcp-failure-driven-sync`.
3. `tv-mcp-failure-driven-sync` checks upstream main and decides whether a local patch is still needed.
