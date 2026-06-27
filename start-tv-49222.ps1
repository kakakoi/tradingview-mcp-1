# TradingView MCP 用 起動確認スクリプト
# 目的:
# - TradingView Desktop を Codex / MCP 用に 49222 ポートで起動する
# - すでに 49222 が使える場合は、追加起動しない
# - 旧 9222 ポートは使わない

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$cdpUrl = "http://127.0.0.1:49222/json/version"

function Test-TradingViewCdp {
  try {
    return Invoke-RestMethod $cdpUrl -TimeoutSec 2
  } catch {
    return $null
  }
}

function Find-TradingViewExe {
  # 公式サイト配布の TradingView Desktop / App Installer 版を優先して探す
  $packages = Get-AppxPackage *TradingView* -ErrorAction SilentlyContinue

  if (-not $packages) {
    return $null
  }

  # TradingView.Desktop を優先
  $preferred = $packages | Where-Object { $_.Name -like "*TradingView.Desktop*" } | Select-Object -First 1

  if (-not $preferred) {
    $preferred = $packages | Select-Object -First 1
  }

  if (-not $preferred.InstallLocation) {
    return $null
  }

  $exe = Get-ChildItem $preferred.InstallLocation -Filter "TradingView.exe" -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty FullName

  return $exe
}

Write-Host ""
Write-Host "=== TradingView MCP 起動確認 ==="
Write-Host "確認中: 127.0.0.1:49222"
Write-Host ""

$existing = Test-TradingViewCdp

if ($existing) {
  Write-Host "OK: TradingView はすでに Codex 用に起動済みです。"
  Write-Host "次の操作: Codex の新規セッションで MCP 'tradingview-public-49222' を使ってください。"
  Write-Host ""
  $existing
  exit 0
}

Write-Host "49222 が未起動です。TradingView Desktop を探します..."
$exe = Find-TradingViewExe

if (-not $exe) {
  Write-Host ""
  Write-Host "NG: TradingView.exe が見つかりませんでした。"
  Write-Host "TradingView Desktop を公式サイトからインストールしてください。"
  Write-Host "インストール後、このスクリプトを再実行してください。"
  exit 1
}

Write-Host "見つかったTradingView:"
Write-Host $exe
Write-Host ""
Write-Host "TradingView を 49222 ポートで起動します..."
Write-Host ""

Start-Process -FilePath $exe -ArgumentList "--remote-debugging-port=49222"

Start-Sleep -Seconds 5

Write-Host "起動後の確認中: 127.0.0.1:49222"
$started = Test-TradingViewCdp

if ($started) {
  Write-Host ""
  Write-Host "OK: TradingView は Codex 用に起動できました。"
  Write-Host "次の操作: Codex の新規セッションで MCP 'tradingview-public-49222' を使ってください。"
  Write-Host ""
  $started
  exit 0
}

Write-Host ""
Write-Host "NG: TradingView を起動しましたが、49222 の応答が確認できませんでした。"
Write-Host "対応:"
Write-Host "1. TradingView を画面から完全終了してください。"
Write-Host "2. このスクリプトをもう一度実行してください。"
Write-Host "3. それでも失敗する場合は、旧 9222 や tv_launch には戻らず、エラー内容を確認してください。"
exit 1
