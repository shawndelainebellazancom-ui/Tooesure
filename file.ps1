Write-Host "=== TOOENSURE BLAZOR DIAGNOSTIC ===" -ForegroundColor Cyan

# 1. Show .csproj static asset rules
Write-Host "`n--- .csproj Static Asset Rules ---" -ForegroundColor Yellow
Select-String -Path *.csproj -Pattern "_headers","_redirects","StaticWebAssets","Content" | ForEach-Object {
    Write-Host $_.Line
}

# 2. Clean + Publish
Write-Host "`n--- Running dotnet clean ---" -ForegroundColor Yellow
dotnet clean

Write-Host "`n--- Running dotnet publish ---" -ForegroundColor Yellow
dotnet publish -c Release -o output/wwwroot

# 3. Check publish output
Write-Host "`n--- Checking publish output ---" -ForegroundColor Yellow

$paths = @(
    "output/wwwroot/_headers",
    "output/wwwroot/_redirects",
    "output/wwwroot/_framework",
    "output/wwwroot/_framework/blazor.boot.json",
    "output/wwwroot/_framework/dotnet.js",
    "output/wwwroot/_framework/dotnet.wasm"
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "[OK] $p" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $p" -ForegroundColor Red
    }
}

# 4. List all files in publish output
Write-Host "`n--- Listing output/wwwroot ---" -ForegroundColor Yellow
Get-ChildItem -Recurse output/wwwroot | Select-Object FullName

Write-Host "`n=== END OF REPORT ===" -ForegroundColor Cyan
