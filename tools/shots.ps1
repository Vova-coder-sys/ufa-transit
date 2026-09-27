$ErrorActionPreference = 'Stop'
$godot = Join-Path $env:LOCALAPPDATA 'Programs\Godot\Godot_v4.7.2-stable_win64_console.exe'
$root = Split-Path -Parent $PSScriptRoot
$shots = Join-Path $root 'shots'
New-Item -ItemType Directory -Force -Path $shots | Out-Null

$jobs = @(
  @{ n = 'trolley_night'; a = @('--role=driver', '--route=tb-13', '--model=uttz6243', '--view=chase', '--period=evening', '--weather=rain') },
  @{ n = 'tram_cabin'; a = @('--role=driver', '--route=tram-1', '--model=ktm619', '--view=cabin', '--weather=snow') },
  @{ n = 'conductor'; a = @('--role=conductor', '--route=bus-30', '--model=nefaz', '--view=cabin') },
  @{ n = 'passenger'; a = @('--role=passenger', '--route=bus-30', '--model=vector', '--view=chase') },
  @{ n = 'menu'; a = @('--menu') },
  @{ n = 'gazelle'; a = @('--role=driver', '--route=bus-25', '--model=gazelle', '--view=side') },
  @{ n = 'tatra'; a = @('--role=driver', '--route=tram-6', '--model=tatraT3', '--view=side') },
  @{ n = 'yutong'; a = @('--role=driver', '--route=bus-101', '--model=yutong', '--view=side') }
)
foreach ($job in $jobs) {
  $out = Join-Path $shots ("{0}.png" -f $job.n)
  if (Test-Path $out) { Remove-Item $out -Force }
  $args = @('--path', (Join-Path $root 'godot'), '--resolution', '1600x900', '--') + @("--shot=$out") + $job.a
  & $godot @args 2>&1 | Where-Object { $_ -match 'SCRIPT ERROR|ERROR:' } | Select-Object -First 6
  Write-Host $out
}
