$projectPath = "C:\Users\Administrator\Desktop\website2"
$checkInterval = 30

Set-Location $projectPath

Write-Host "GitHub auto sync started" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Red

while ($true) {
    git pull 2>&1 | Out-Null
    $status = git status --porcelain
    if ($status) {
        $time = Get-Date -Format "HH:mm:ss"
        $fileCount = ($status | Measure-Object).Count
        $commitMsg = "auto sync: $fileCount files - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git add .
        git commit -m $commitMsg 2>&1 | Out-Null
        git push 2>&1 | Out-Null
        Write-Host "[$time] Synced $fileCount files to GitHub" -ForegroundColor Green
    }
    Start-Sleep -Seconds $checkInterval
}
