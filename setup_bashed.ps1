$ScriptPath = Join-Path $PSScriptRoot "bashed_notifer.ps1"

if (-not (Test-Path $ScriptPath)) {
    Write-Host "Couldn't finished bashed_notifer.ps1 in $PPScriptRoot" -ForegroundColor Red
    exit 1
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NotProfile -ExecutionPolicy Bypass -Windowstyle Hidden -File `"$scriptPath`""

$onLogon =New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$atSeven = New-ScheduledTaskTrigger -Daily -At "19:00"

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable


Register-ScheduledTask -TaskName "BasheDisplayNotifer" `
    -Trigger @($onLogon, $atSeven) `
    -Action $action `
    -Settings $settings `
    -Description "Daily tasks.txt summary and 7pm bashed reminder" `
    -Force | Out-Null


Write-Host "Task 'BashedDailyNotifer' registered" -ForegroundColor Green
