$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
$ffmpeg  = "C:\Users\citru\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffmpeg.exe"
$ffprobe = "C:\Users\citru\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1.1-full_build\bin\ffprobe.exe"
$mediaDir = "c:\Users\citru\OneDrive\Documents\GitHub\Anshu Patel Portfolio\media"
$log = "c:\Users\citru\OneDrive\Documents\GitHub\Anshu Patel Portfolio\compress_log.txt"
"=== Compression started $(Get-Date) ===" | Out-File $log -Encoding utf8

function Log($msg) { $msg | Out-File $log -Append -Encoding utf8; Write-Host $msg }

# ── VIDEOS ──
$videos = Get-ChildItem -Recurse $mediaDir -Include "*.mp4","*.mov" | Where-Object { $_.Length -gt 5MB }
Log "Found $($videos.Count) videos to process"

foreach ($v in $videos) {
    $origMB = [math]::Round($v.Length/1MB, 1)
    Log ""
    Log "Processing video: $($v.Name) ($origMB MB)"

    $bitrateRaw = & $ffprobe -v quiet -select_streams v:0 -show_entries stream=bit_rate -of csv=p=0 $v.FullName
    $bitrate = [int]($bitrateRaw -replace '\D','')
    if ($bitrate -gt 0 -and $bitrate -lt 4000000) {
        Log "  Skipping - already at $([math]::Round($bitrate/1000))k bps"
        continue
    }

    $tmp = $v.FullName + ".tmp.mp4"
    & $ffmpeg -y -i $v.FullName -c:v libx264 -crf 18 -preset fast -c:a aac -b:a 128k -movflags faststart $tmp
    if ($LASTEXITCODE -eq 0 -and (Test-Path $tmp)) {
        $newMB = [math]::Round((Get-Item $tmp).Length/1MB, 1)
        if ((Get-Item $tmp).Length -lt $v.Length) {
            Move-Item $tmp $v.FullName -Force
            Log "  Done: $origMB MB -> $newMB MB (saved $([math]::Round($origMB - $newMB, 1)) MB)"
        } else {
            Remove-Item $tmp -Force
            Log "  Output not smaller, kept original"
        }
    } else {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
        Log "  FAILED"
    }
}

# ── JPEG IMAGES ──
$images = Get-ChildItem -Recurse $mediaDir -Include "*.jpg","*.jpeg" | Where-Object { $_.Length -gt 1MB }
Log ""
Log "=== Images ==="
Log "Found $($images.Count) JPEGs to process"

foreach ($img in $images) {
    $origMB = [math]::Round($img.Length/1MB, 1)
    Log ""
    Log "Processing image: $($img.Name) ($origMB MB)"
    $tmp = $img.FullName + ".tmp.jpg"
    & $ffmpeg -y -i $img.FullName -q:v 2 $tmp
    if ($LASTEXITCODE -eq 0 -and (Test-Path $tmp)) {
        $newMB = [math]::Round((Get-Item $tmp).Length/1MB, 1)
        if ((Get-Item $tmp).Length -lt $img.Length) {
            Move-Item $tmp $img.FullName -Force
            Log "  Done: $origMB MB -> $newMB MB (saved $([math]::Round($origMB - $newMB, 1)) MB)"
        } else {
            Remove-Item $tmp -Force
            Log "  Output not smaller, kept original"
        }
    } else {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
        Log "  FAILED"
    }
}

# ── PNG IMAGES ──
$pngs = Get-ChildItem -Recurse $mediaDir -Include "*.png" | Where-Object { $_.Length -gt 2MB }
Log ""
Log "=== Large PNGs ==="
Log "Found $($pngs.Count) PNGs to process"

foreach ($png in $pngs) {
    $origMB = [math]::Round($png.Length/1MB, 1)
    Log ""
    Log "Processing PNG: $($png.Name) ($origMB MB)"
    $tmp = $png.FullName + ".tmp.png"
    & $ffmpeg -y -i $png.FullName -compression_level 9 -pred mixed $tmp
    if ($LASTEXITCODE -eq 0 -and (Test-Path $tmp)) {
        $newMB = [math]::Round((Get-Item $tmp).Length/1MB, 1)
        if ((Get-Item $tmp).Length -lt $png.Length) {
            Move-Item $tmp $png.FullName -Force
            Log "  Done: $origMB MB -> $newMB MB (saved $([math]::Round($origMB - $newMB, 1)) MB)"
        } else {
            Remove-Item $tmp -Force
            Log "  Output not smaller, kept original"
        }
    } else {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
        Log "  FAILED"
    }
}

$totalAfter = (Get-ChildItem -Recurse $mediaDir -File | Measure-Object Length -Sum).Sum
Log ""
Log "=== DONE $(Get-Date) ==="
Log "Total media size after: $([math]::Round($totalAfter/1MB, 0)) MB"
Read-Host "Press Enter to close"
