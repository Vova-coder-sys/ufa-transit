param(
  [string]$Name = "shot",
  [string]$Role = "driver",
  [string]$Route = "tram-18",
  [string]$Model = "pesa",
  [string]$View = "side",
  [string]$Weather = "clear",
  [string]$Period = "day",
  [string]$Opts = ""
)
$ErrorActionPreference = 'Stop'
$godot = Join-Path $env:LOCALAPPDATA 'Programs\Godot\Godot_v4.7.2-stable_win64_console.exe'
$root = Split-Path -Parent $PSScriptRoot
$shots = Join-Path $root 'shots'
New-Item -ItemType Directory -Force -Path $shots | Out-Null
$out = Join-Path $shots "$Name.png"
if (Test-Path $out) { Remove-Item $out -Force }
$extra = @()
if ($Opts -ne "") { $extra = $Opts.Split(" ") | Where-Object { $_ -ne "" } }
$call = @('--path', (Join-Path $root 'godot'), '--resolution', '1600x900', '--',
  "--shot=$out", "--role=$Role", "--route=$Route", "--model=$Model", "--view=$View",
  "--weather=$Weather", "--period=$Period") + $extra
& $godot @call 2>&1 | Where-Object { $_ -match 'UFA_|ERROR|SCRIPT' }
Write-Host $out
