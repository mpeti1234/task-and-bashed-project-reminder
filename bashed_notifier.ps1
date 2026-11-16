# prevent multiple instances running at the same time

$isNew = $false
$mutex = New-Object System.Threading.Mutex($true, "Global\BashedNotifierMute", [ref]$isNew)

if (-not $isNew) { exit }


try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    # default powershell app id so windows lets us push toast notifications
    $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

    function Show-Notification ($title, $body) {
        $t = [System.Security.SecurityElement]::Escape($title)
        $b = [System.Security.SecurityElement]::Escape($body)

        $xml = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text>$t</text>
            <text>$b</text>
        </binding>
    </visual>
</toast>
"@

        $doc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $doc.LoadXml($xml)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $doc
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
    }

    $desktop = [Environment]::GetFolderPath('Desktop')
    $tasksPath = Join-Path $desktop "tasks.txt"
    $dataDir = Join-Path $env:LOCALAPPDATA "bashed"
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
    }
    $statePath = Join-Path $dataDir "state.json"

    



    $state = @{
        tasksSentOn    = ""
        reminderSentOn = ""
    }

    if (Test-Path $statePath) {
        try {
            $saved = Get-Content $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($saved.tasksSentOn) { $state.tasksSentOn = $saved.tasksSentOn }
            if ($saved.reminderSentOn) { $state.reminderSentOn = $saved.reminderSentOn }
        }
        catch {}
    }

    $now = Get-Date
    $today = $now.ToString("yyyy-MM-dd")
    $targetTime = (Get-Date -Hour 19 -Minute 0 -Second 0).AddSeconds(-30)
    $justSentTasks = $false

    # daily task chech
    if ($state.tasksSentOn -ne $today) {
        if (-not (Test-Path $tasksPath)) {
            Set-Content -Path $tasksPath -Value "- test bashed script" -Encoding UTF8
            Show-Notification "tasks.txt created" "Made a new tasks.txt on your desktop with a sample task."
        }
        else {
            $tasks = @(Get-Content $tasksPath -Encoding UTF8 | Where-Object { $_.Trim() -ne "" })
            if ($tasks.Count -eq 0) {
                Show-Notification "Daily tasks" "nothing in tasks.txt today"
            }
            else {
                $summary = ($tasks | Select-Object -First 4 | ForEach-Object { "- $($_.Trim())" }) -join "`n"
                if ($tasks.Count -gt 4) {
                    $summary += "`n+ $($tasks.Count - 4) more..."
                }
                Show-Notification "Today's tasks ($($tasks.Count))" $summary
            }
        }

        $state.tasksSentOn = $today
        $state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
        $justSentTasks = $true
    }


    # 7pm reminder (or 5 minutes after turn on your pc after 7pm)
    if ($now -ge $targetTime -and $state.reminderSentOn -ne $today) {
        if ($justSentTasks) {
            Start-Sleep -Seconds 300
        }

        Show-Notification "bashed" "time to work on the bashed project"

        $state.reminderSentOn = $today
        $state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
    }
}
finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
