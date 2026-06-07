$ffmpeg = "C:\Users\citru\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$root = "c:\Users\citru\OneDrive\Documents\GitHub\Anshu Patel Portfolio\media"
$log = "c:\Users\citru\OneDrive\Documents\GitHub\Anshu Patel Portfolio\scripts\compress-log.txt"

"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Starting video compression" | Out-File $log -Encoding utf8

$videos = Get-ChildItem -Recurse $root -Filter "*.mp4" | Sort-Object Length -Descending
$total = $videos.Count
$i = 0
$totalSaved = 0

foreach ($v in $videos) {
    $i++
    $temp = $v.FullName + ".tmp.mp4"
    $origMB = [math]::Round($v.Length / 1MB, 1)
    $msg = "[$i/$total] $($v.Name) ($origMB MB)"
    Write-Host $msg -ForegroundColor Cyan
    "$(Get-Date -Format 'HH:mm:ss') START $msg" | Out-File $log -Append -Encoding utf8

    & $ffmpeg -y -i $v.FullName -c:v libx264 -preset veryfast -crf 26 -c:a aac -b:a 128k -movflags +faststart $temp 2>> $log

    if ($LASTEXITCODE -eq 0 -and (Test-Path $temp)) {
        $newSize = (Get-Item $temp).Length
        $newMB = [math]::Round($newSize / 1MB, 1)
        if ($newSize -lt $v.Length) {
            $saved = [math]::Round(($v.Length - $newSize) / 1MB, 1)
            $totalSaved += ($v.Length - $newSize)
            Move-Item -Force $temp $v.FullName
            $result = "  SAVED ${saved} MB -> ${newMB} MB"
            Write-Host $result -ForegroundColor Green
        } else {
            Remove-Item $temp
            $result = "  Already optimal, kept original"
            Write-Host $result -ForegroundColor Yellow
        }
        "$(Get-Date -Format 'HH:mm:ss') DONE $result" | Out-File $log -Append -Encoding utf8
    } else {
        if (Test-Path $temp) { Remove-Item $temp }
        $result = "  ERROR - kept original"
        Write-Host $result -ForegroundColor Red
        "$(Get-Date -Format 'HH:mm:ss') $result" | Out-File $log -Append -Encoding utf8
    }
}

$totalSavedMB = [math]::Round($totalSaved / 1MB, 1)
$summary = "$(Get-Date -Format 'HH:mm:ss') COMPLETE - Total saved: ${totalSavedMB} MB across $total videos"
Write-Host $summary -ForegroundColor Magenta
$summary | Out-File $log -Append -Encoding utf8
