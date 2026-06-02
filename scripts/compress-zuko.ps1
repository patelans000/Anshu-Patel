# Compress Zuko video with ffmpeg
# Usage: Open PowerShell in repo root and run: .\scripts\compress-zuko.ps1

$in = "videos\Zuko.mp4"
$out = "videos\Zuko-compressed.mp4"

# Check for ffmpeg
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  Write-Host "ffmpeg not found in PATH. Install ffmpeg (https://ffmpeg.org/download.html) or via Chocolatey: 'choco install ffmpeg'" -ForegroundColor Yellow
  exit 1
}

Write-Host "Compressing $in -> $out" -ForegroundColor Cyan

# Compression settings: CRF 21 (good quality), preset slow, audio 160k
ffmpeg -y -i "$in" -c:v libx264 -preset slow -crf 21 -c:a aac -b:a 160k "$out"

if ($LASTEXITCODE -ne 0) {
  Write-Host "ffmpeg reported an error (exit code $LASTEXITCODE)." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host "Compression complete. File sizes:" -ForegroundColor Green
Get-Item "$in" | Select-Object Name,@{Name='SizeMB';Expression={[math]::Round($_.Length/1MB,2)}}
Get-Item "$out" | Select-Object Name,@{Name='SizeMB';Expression={[math]::Round($_.Length/1MB,2)}}

Write-Host "Review the compressed file before replacing the original. To overwrite original if happy, run:` Move-Item -Force "$out" "$in"`" -ForegroundColor Yellow
