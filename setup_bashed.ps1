$ScriptPath = Join-Path $PSScriptRoot "bashed_notifier.ps1"

if (-not (Test-Path $ScriptPath)) {
    Write-Host "Couldn't finished bashed_notifier.ps1 in $PPScriptRoot" -ForegroundColor Red
    exit 1
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NotProfile -ExecutionPolicy Bypass -Windowstyle Hidden -File `"$scriptPath`""

$onLogon =New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$atSeven = New-ScheduledTaskTrigger -Daily -At "19:00"

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable


Register-ScheduledTask -TaskName "BasheDisplayNotifier" `
    -Trigger @($onLogon, $atSeven) `
    -Action $action `
    -Settings $settings `
    -Description "Daily tasks.txt summary and 7pm bashed reminder" `
    -Force | Out-Null


Write-Host "Task 'BashedDailyNotifier' registered" -ForegroundColor Green
