#!/usr/bin/env pwsh
# Spins up the full local dev stack on Windows:
#   - Postgres + Rails in Docker (docker-compose)
#   - Vite dev server on the host, since the `web` image has no Node.js
#     and bin/vite's Bundler stub isn't usable host-side either (no
#     host bundle install) - `npx vite` is the one that actually works.
# See CLAUDE.md "Common Development Commands" for the background.

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Test-Path "node_modules")) {
    Write-Host "==> Installing npm packages..." -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) { throw "npm install failed" }
}

Write-Host "==> Starting Postgres + Rails (docker-compose up -d)..." -ForegroundColor Cyan
docker-compose up -d
if ($LASTEXITCODE -ne 0) { throw "docker-compose up failed" }

Write-Host "==> Preparing the database (create + migrate)..." -ForegroundColor Cyan
docker-compose exec -T web bin/rails db:prepare
if ($LASTEXITCODE -ne 0) { throw "db:prepare failed" }

Write-Host ""
Write-Host "==> Rails is up at http://localhost:3000" -ForegroundColor Green
Write-Host "==> Starting Vite on the host - Ctrl+C stops just this; Rails/Postgres keep running." -ForegroundColor Cyan
Write-Host "    Run 'docker-compose down' separately when you want to stop those too." -ForegroundColor DarkGray
Write-Host ""

npx vite
