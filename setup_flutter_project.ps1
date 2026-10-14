$ErrorActionPreference = "Stop"
Write-Host "BudgetBuddy platform setup" -ForegroundColor Cyan
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Error "Flutter was not found. Install Flutter and add flutter\bin to PATH, then reopen PowerShell."
}
flutter create . --platforms=android,windows
if ($LASTEXITCODE -ne 0) { throw "flutter create failed. Review the Flutter error above." }
$manifest = Join-Path $PSScriptRoot "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifest) {
  $content = Get-Content $manifest -Raw
  if ($content -notmatch 'android.permission.INTERNET') {
    $content = $content -replace '(?s)(<manifest[^>]*>)', '$1' + "`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
    Set-Content -Path $manifest -Value $content -Encoding UTF8
  }
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed. Review the Flutter error above." }
Write-Host "Setup finished. Next run: dart format . ; flutter analyze ; flutter test ; flutter run" -ForegroundColor Green
