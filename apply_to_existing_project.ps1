param(
    [string]$TargetProject = "D:\Code\NhawowMobile\nhawow_mobile"
)

$ErrorActionPreference = "Stop"
$SourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path (Join-Path $TargetProject "pubspec.yaml"))) {
    throw "Không tìm thấy Flutter project tại: $TargetProject"
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path (Split-Path -Parent $TargetProject) ("nhawow_mobile_backup_" + $stamp)
New-Item -ItemType Directory -Force $backup | Out-Null

Copy-Item (Join-Path $TargetProject "lib") (Join-Path $backup "lib") -Recurse -Force
if (Test-Path (Join-Path $TargetProject "assets")) {
    Copy-Item (Join-Path $TargetProject "assets") (Join-Path $backup "assets") -Recurse -Force
}
Copy-Item (Join-Path $TargetProject "pubspec.yaml") (Join-Path $backup "pubspec.yaml") -Force

Copy-Item (Join-Path $SourceRoot "lib") (Join-Path $TargetProject "lib") -Recurse -Force
Copy-Item (Join-Path $SourceRoot "assets") (Join-Path $TargetProject "assets") -Recurse -Force
Copy-Item (Join-Path $SourceRoot "docs") (Join-Path $TargetProject "docs") -Recurse -Force
Copy-Item (Join-Path $SourceRoot "test") (Join-Path $TargetProject "test") -Recurse -Force
Copy-Item (Join-Path $SourceRoot ".vscode") (Join-Path $TargetProject ".vscode") -Recurse -Force
Copy-Item (Join-Path $SourceRoot "pubspec.yaml") (Join-Path $TargetProject "pubspec.yaml") -Force

Write-Host "Đã cập nhật Mobile. Backup: $backup" -ForegroundColor Green
Write-Host "Chạy flutter clean, flutter pub get --offline và flutter analyze." -ForegroundColor Cyan
