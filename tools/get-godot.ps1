$ErrorActionPreference = 'Stop'
$version = '4.7.2-stable'
$root = Join-Path $env:LOCALAPPDATA 'Programs\Godot'
$templatesDir = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable"
New-Item -ItemType Directory -Force -Path $root | Out-Null

$editorZip = Join-Path $root "Godot_v$version`_win64.exe.zip"
$editorExe = Join-Path $root "Godot_v$version`_win64.exe"
$tpz = Join-Path $root "Godot_v$version`_export_templates.tpz"

$ProgressPreference = 'SilentlyContinue'

if (-not (Test-Path $editorExe)) {
  Write-Host 'downloading editor'
  Invoke-WebRequest -Uri "https://github.com/godotengine/godot/releases/download/$version/Godot_v$version`_win64.exe.zip" -OutFile $editorZip
  Expand-Archive -Path $editorZip -DestinationPath $root -Force
  Remove-Item $editorZip -Force
}
Write-Host "editor: $editorExe"

if (-not (Test-Path (Join-Path $templatesDir 'windows_release_x86_64.exe'))) {
  if (-not (Test-Path $tpz)) {
    Write-Host 'downloading export templates'
    Invoke-WebRequest -Uri "https://github.com/godotengine/godot/releases/download/$version/Godot_v$version`_export_templates.tpz" -OutFile $tpz
  }
  Write-Host 'installing export templates'
  $stage = Join-Path $root 'tpz'
  if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  $zipCopy = Join-Path $root 'templates.zip'
  Copy-Item $tpz $zipCopy -Force
  Expand-Archive -Path $zipCopy -DestinationPath $stage -Force
  New-Item -ItemType Directory -Force -Path $templatesDir | Out-Null
  Get-ChildItem (Join-Path $stage 'templates') -File | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $templatesDir $_.Name) -Force
  }
  Remove-Item $zipCopy -Force
  Remove-Item $stage -Recurse -Force
  Remove-Item $tpz -Force
}
Write-Host "templates: $templatesDir"
Write-Host 'GODOT_SETUP_DONE'
