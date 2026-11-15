# prevent multiple instances running at the same time

$isNew = $false
$mutex = New-Object System.Threading.Mutex($true, "Global\BashedNotiferMute", [ref]$isNew)

if (-not $isNew) { exit }

try {
    [Windows.UI.Notifications.ToolsNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    # default powershell app id so windows lets us push toast notifications
    $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

    function Show-Notification ($title, $body) {
        $t = [System.Security.SecurityElement]::Escape($title)
        $b = [System.Security.SecurityElement]::Escape($body)

        $xml = @"
<toast>
    <visual>
        <binding template = "ToastGeneric">
            <text>$t<text>
            <text>$b<text>
        </binding>
    </visual>
</toast>
"@

        $doc = New-Object Windows.Data.Xml.Dom.XmlDocument
        $doc.LoadXml($xml)
        $toast = New-Object Windows.UI.Notifications.ToastNotification $doc
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
    }

    $desktp = [Environment]::GetFolderPath('Desktop')
    $taskPath = Join-Path $env:LOCALAPPDATA "bashed"
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
        } catch {}
    }

    $now = Get-Date
    $today = $now.ToString("yyyy-MM-dd")
    $targetTime = (Get-Date -Hour 19 -Minute 0 -Second 0).AddSeconds(-30)
    $justSentTasks = $false

    # daily task chech




}
