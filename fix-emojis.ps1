$filePath = "docs/index.html"
$content = Get-Content $filePath -Encoding UTF8 -Raw

# Fix broken emoji placeholders - replace X_EMOJI_X with praying hands
$content = $content -replace [regex]::Escape("X_EMOJI_X"), "🙏"

# Fix corrupted em dashes and sparkles
$content = $content -replace "â€"", "—"
$content = $content -replace "âœ¨", "✨"

$content | Set-Content $filePath -Encoding UTF8
Write-Host "All broken emojis have been fixed!"
