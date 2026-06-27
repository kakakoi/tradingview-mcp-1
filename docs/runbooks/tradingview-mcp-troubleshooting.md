# TradingView MCP Troubleshooting Runbook

## Purpose

Reusable checklist for TradingView MCP failures around Pine Editor, Monaco detection, strategy recognition, and Strategy Tester metrics. Use this to keep incident response narrow, reproducible, and separated from Pine strategy changes.

Use this runbook mostly in `consult` for diagnosis design and in `tv-validate` for one-layer smoke tests. Use `ops-finalize` only for recording or committing the runbook/result. Do not use it to justify broad multi-step TradingView operations.

## Fixed Rules

- Use only the canonical MCP route: `tradingview-public-49222`.
- Use only the canonical CDP endpoint: `127.0.0.1:49222`.
- Do not use old `tradingview`, `tv_launch`, `9222`, or legacy MCP routes.
- Treat TradingView UI state, Pine Editor state, chart study state, and Strategy Tester state as separate layers.
- Do not read or print Pine source, cookies, tokens, localStorage, or personal account data during diagnosis.
- Do not compile, add to chart, fetch Strategy Tester metrics, or change strategy logic unless the active work mode explicitly allows it.

## Smoke Execution Rules

- Do not assume registered MCP and freshly spawned MCP processes use the same CDP endpoint.
- Registered `tradingview-public-49222` may have `TV_CDP_PORT=49222`, while a manually spawned local MCP process may fall back to `9222`.
- When starting any fresh MCP process for smoke tests, explicitly set:
  - `TV_CDP_HOST=127.0.0.1`
  - `TV_CDP_PORT=49222`
- Before smoke, confirm:
  - `http://127.0.0.1:49222/json/version`
  - or `tradingview-public-49222.tv_health_check`
- After editing MCP source files, restart the MCP server before testing.
- If a patched tool does not return expected new fields such as `source`, suspect stale MCP server code first.
- For `pine_new`, expected patched success includes:
  - `source: "pineEditorTestApi"`
- For `pine_set_source`, expected patched success includes:
  - `source: "pineEditorTestApi"`
  - `action: "setEditorText"`
  - `lines_set` or `chars_set`
- If smoke fails with `CDP connection failed` while health check succeeds, compare the connection path and environment variables before retrying the tool.
- If MCP transport closes, do not retry the same operation repeatedly. Start a new Codex session or reconnect MCP, then run exactly one smoke.
- Smoke tests must stop after one layer. Do not continue from source reflection to compile, add-to-chart, or Strategy Tester metrics unless explicitly requested.

## Layer Order

1. CDP reachability: confirm `127.0.0.1:49222` responds.
2. MCP availability: confirm `tradingview-public-49222` tools are loaded.
3. Chart context: confirm symbol, timeframe, chart type, and visible studies when needed.
4. Pine Editor UI: check Pine button, bottom panel, `.monaco-editor.pine-editor-monaco`, and editor visibility.
5. Pine Editor API: check `TradingViewApi.pineEditorTestApi()` and methods such as `openEditor`, `openNewScript`, `setEditorText`, and `focusEditor`.
6. Strategy visibility: confirm whether the strategy appears as a chart study.
7. Strategy Tester recognition: separately confirm whether strategy data APIs can identify a strategy.
8. Metrics extraction: only after Strategy Tester recognition is stable, query metrics.

## Failure Classification

- CDP unavailable: TradingView is not reachable on `127.0.0.1:49222`.
- MCP session stale: local files changed but the running MCP server has not reloaded them.
- Pine Editor DOM unavailable: Pine panel or Monaco DOM is missing or hidden.
- Pine Editor ready mismatch: DOM is visible but MCP readiness detection cannot access the editor.
- Pine Editor API path unavailable: `pineEditorTestApi` or required methods are missing.
- Indicator add stuck state: `chart_manage_indicator(add)` failure can leave TradingView in a bad state for later add or Pine operations.
- Study visible but not strategy-recognized: a visible study is not enough to prove Strategy Tester can identify it.
- Strategy Tester uncomputed: panel or internal tester data has not populated yet.
- Strategy Tester extraction bug: internal or DOM metrics paths cannot find metrics even after a strategy is visible.
- TradingView runtime error: console errors such as `unexpected study id` may indicate chart layout or study restoration problems.

## Failure Routing Table

| Symptom | Classification | Next skill | Stop rule |
|---|---|---|---|
| `data_get_strategy_results` returns `success: true`, `metric_count: 0`, `metrics: {}` | Strategy Tester extraction bug | `tv-mcp-failure-driven-sync` | Do not patch local source in the capture task. |
| Strategy is visible as a chart study, but trades/results APIs return `No strategy found` | Strategy Tester recognition or extraction bug | `tv-mcp-failure-driven-sync` | Do not infer health from chart study visibility. |
| Strategy Tester UI has values, but structured API is empty | Strategy Tester extraction bug | `tv-mcp-failure-driven-sync` | UI values may be recorded as observed evidence only. |

## Failure-driven upstream sync

When a TradingView MCP failure occurs:

1. Classify the failed layer first.
2. Do not immediately patch local code.
3. Check whether upstream `tradesdontlie/tradingview-mcp` has changed related files.
4. Prefer checking upstream in a separate worktree rather than modifying the stable local working tree.
5. If upstream fixes the failed layer, prefer upstream and consider retiring the local patch.
6. If upstream does not fix the failed layer, keep or create the smallest local patch.
7. Push only to a personal fork.
8. Record the decision in this runbook.

Relevant upstream files to check first:

- `src/core/pine.js`
- `src/tools/pine.js`
- `src/core/data.js`
- `src/tools/data.js`
- `src/core/ui.js`
- `src/connection.js`
- `src/core/tab.js`

Status labels:

- `patch-still-needed`
- `patch-obsolete`
- `upstream-likely-fixes`
- `upstream-unknown-test-needed`
- `needs-local-minimal-patch`
- `blocked-wait-for-upstream`
- `needs-user-choice`

Recommended layout:

- Stable local repo: `C:\tv-mcp-public-test`
- Optional upstream test worktree: `C:\tv-mcp-upstream-test`
- Personal fork branch: `tradingview-mcp-pine-editor-fix`

Do not enable automatic pull/update on each MCP startup. Use controlled upstream checks after failure or on explicit request.

In `consult`, do not pull, merge, rebase, cherry-pick, reset, edit files, run TradingView MCP, reflect Pine source, compile, add to chart, or read Strategy Tester metrics during the upstream comparison. End with exactly one recommended next action.

## Confirmed Fixes

- `pine_new(strategy)` now has a `pineEditorTestApi` path in commit `b09edd6`.
- Confirmed smoke result after MCP server restart:

| Item | Value |
|---|---|
| success | `true` |
| source | `pineEditorTestApi` |
| type | `strategy` |
| action | `new_script_created` |

- The smoke result confirms the patched `pine_new(strategy)` route can create a new strategy template through `TradingViewApi.pineEditorTestApi`.
- If `source` is missing from `pine_new` output after editing MCP source files, first suspect that the running MCP server still has old code loaded.

## Known Risk Areas

- `chart_manage_indicator(add)` is weak for re-adding local custom Pine strategies by exact name.
- `chart_manage_indicator(remove)` can succeed while later exact-name add still fails.
- Study visible and Strategy Tester recognized are separate states; do not treat one as proof of the other.
- `data_get_strategy_results` returning `No strategy found` is unresolved.
- `unexpected study id` runtime errors are unresolved.
- Strategy Tester metrics retrieval is not complete.
- `bottomWidgetBar.hideWidget` may be unavailable on newer TradingView builds; `close` and `hide` may exist instead.
- `window.monaco` may be absent even when `.monaco-editor.pine-editor-monaco` is visible.
- React fiber based Monaco discovery can be state-sensitive.

## Minimal Test Order

1. Confirm CDP on `127.0.0.1:49222`.
2. Confirm MCP server has restarted after local source edits.
3. Optionally call `chart_get_state` once to confirm fixed symbol and timeframe.
4. Call `pine_new({ type: "strategy" })` once.
5. Stop and record the returned fields.
6. If success includes `source: "pineEditorTestApi"`, the patched route is active.
7. If success includes `source: "legacy_monaco_setValue"`, fallback worked and `testApiFallback` should be reviewed.
8. If `source` is missing, check wrapper formatting and MCP server reload before repeating tool operations.
9. Do not proceed to compile, add-to-chart, or Strategy Tester metrics in the same minimal smoke.

## Do Not Do

- Do not use old `tradingview`, `tv_launch`, or `9222`.
- Do not run `git add .` or `git add -A` in this repository.
- Do not stage unrelated files such as `package-lock.json`, `src/connection.js`, `src/core/tab.js`, or local launch scripts unless the task explicitly targets them.
- Do not repeatedly call the same TradingView MCP operation after one clear failure.
- Do not use `chart_manage_indicator(add)` as the primary way to restore a local custom Pine strategy without a separate recovery plan.
- Do not call `chart_manage_indicator(remove)` on a local custom Pine strategy unless the restore path is already confirmed.
- Do not infer Strategy Tester health from chart study visibility alone.
- Do not mix Pine source changes, TradingView validation, report updates, and commit/push into one implicit task.

## Next Open Work

- Investigate `data_get_strategy_results` returning `No strategy found` when a strategy appears as a study.
- Separate strategy source detection from chart study visibility in diagnostics.
- Investigate unresolved `unexpected study id` runtime errors.
- Add a read-only diagnostic for Strategy Tester recognition before metrics extraction.
- Consider a minimal patch for newer bottom panel close behavior if UI close/toggle issues recur.
- Consider a safe cleanup path for failed `chart_manage_indicator(add)` states before later Pine operations.

## Incident Note Template

| Field | Value |
|---|---|
| Mode | |
| MCP route | |
| CDP | |
| Layer | |
| Fixed conditions | |
| Action tried once | |
| Result | |
| Classification | |
| Upstream check | |
| Patch status | |
| Next one action | |
