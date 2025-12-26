# MetroTransit Complete Source Code Dump Generator
# UPDATED: Force-include critical Blazor/Cloudflare files (wrangler.toml, _headers, _redirects, .csproj)
# Ensures diagnosis completeness for deployment issues

param(
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$OutputFile = "metro_complete_dump.txt"
)

# Directories to exclude
$excludedDirs = @(
    'bin', 'obj', '.vs', '.idea', '.git', 'node_modules', '.gradle',
    'packages', '.nuget', '.dotnet', 'TestResults', 'coverage', '.publish',
    '.next', 'dist', 'build', '__pycache__', '.venv', 'venv',
    '.kotlin', 'captures', '.externalNativeBuild', '.cxx'
)

# File patterns to exclude (binary/compiled)
$excludedPatterns = @(
    '*.dll', '*.exe', '*.pdb', '*.cache', '*.user', '*.suo', '*.useros',
    '.DS_Store', 'Thumbs.db', '*.Designer.cs', '*.g.cs',
    '*.AssemblyInfo.cs', '*.AssemblyAttributes.cs', '*.g.kt', '*.generated.*',
    '*.jar', 'gradle-wrapper.jar', 'gradle-wrapper.properties'
)

# Additional files to exclude by name (self-referential dumps)
$excludedFiles = @(
    'pmcro_source_dump.txt',
    'metro_source_dump.txt',
    'metro_complete_dump.txt',
    'PROJECT_TREE.txt',
    'google-services.json',
    'keystore.properties',
    'local.properties',
    'gradlew',
    'gradlew.bat'
)

# Expanded extensions to include (added .toml for wrangler)
$includedExtensions = @(
    '.kt', '.java', '.kts', '.md', '.xml', '.json', '.properties',
    '.gradle', '.pro', '.html', '.css', '.js', '.ts', '.toml',  # <-- added .toml
    '.txt', '.yml', '.yaml', '.razor', '.csproj', '.sln', '.config',
    '.sh', '.ps1', '.cshtml', '.resx', '.cs'  # <-- added .cs for Program.cs etc.
)
# CRITICAL FILES TO FORCE-INCLUDE (use full relative paths)
$forceIncludePaths = @(
    'wrangler.toml',
    'website.csproj',  # Assume name; adjust if different
    'wwwroot\_headers',
    'wwwroot\_redirects',
    'wwwroot\index.html',
    'Program.cs',
    'build.sh'
)

function Should-ExcludeFile($fileName, $filePath) {
    $relativePath = $filePath.Substring($ProjectRoot.Length + 1).Replace('\', '/')

    # Force-include if matches any critical path exactly
    if ($forceIncludePaths -contains $relativePath) {
        return $false
    } 
}
function Should-ExcludeFile($fileName, $filePath) {
    # Force-include criticals
    $relativePath = $filePath.Substring($ProjectRoot.Length + 1).Replace('\', '/')
    if ($forceIncludeFiles | Where-Object { $relativePath -like $_ -or $fileName -like $_ }) {
        return $false
    }

    # Explicit excludes
    foreach ($excluded in $excludedFiles) {
        if ($fileName -eq $excluded) {
            return $true
        }
    }

    foreach ($pattern in $excludedPatterns) {
        if ($fileName -like $pattern) {
            return $true
        }
    }

    # Extension filter
    $extension = [System.IO.Path]::GetExtension($fileName).ToLower()
    if ($extension -and -not ($includedExtensions -contains $extension)) {
        Write-Host "Skipping by extension: $relativePath ($extension)" -ForegroundColor Yellow
        return $true
    }

    return $false
}

function Get-SourceFiles($path) {
    $files = @()

    try {
        $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue

        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                if (-not (Should-ExcludeDirectory $item.Name)) {
                    $files += Get-SourceFiles $item.FullName
                }
            } else {
                if (-not (Should-ExcludeFile $item.Name $item.FullName)) {
                    $files += $item
                }
            }
        }
    } catch {
        Write-Warning "Error accessing path: $path"
    }

    return $files
}

# Main execution
Write-Host "MetroTransit COMPLETE Source Code Dump Generator (UPDATED)" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Force-including: wrangler.toml, .csproj, _headers, _redirects, index.html, Program.cs" -ForegroundColor Magenta

$sourceFiles = Get-SourceFiles $ProjectRoot | Sort-Object FullName

Write-Host "Found $($sourceFiles.Count) source files" -ForegroundColor Green

# ... (rest unchanged: progress, output formatting, write to file)
Write-Host ""
Write-Host "Files by type:" -ForegroundColor Cyan
$sourceFiles | Group-Object Extension | Sort-Object Count -Descending | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) files" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Generating source dump..." -ForegroundColor Green

# Create output file
$output = @()
$output += "=" * 80
$output += "METROTRANSIT PROJECT COMPLETE SOURCE CODE DUMP"
$output += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$output += "Project Root: $ProjectRoot"
$output += "Total Files: $($sourceFiles.Count)"
$output += "=" * 80
$output += ""
$output += "INCLUDED DIRECTORIES: wwwroot, source files, configuration"
$output += "EXCLUDED DIRECTORIES: bin, obj, .vs, .git, node_modules, packages"
$output += ""
$output += ""

$fileCount = 0
foreach ($file in $sourceFiles) {
    $fileCount++
    $relativePath = $file.FullName.Substring($ProjectRoot.Length + 1)

    Write-Progress -Activity "Processing files" -Status "$fileCount of $($sourceFiles.Count)" -PercentComplete (($fileCount / $sourceFiles.Count) * 100)

    $output += "=" * 80
    $output += "FILE: $relativePath"
    $output += "SIZE: $([math]::Round($file.Length / 1KB, 2)) KB"
    $output += "=" * 80
    $output += ""

    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        if ($null -ne $content) {
            $output += $content
        } else {
            $output += "[Empty file]"
        }
    } catch {
        $output += "[Error reading file: $($_.Exception.Message)]"
    }

    $output += ""
    $output += ""
}

# Write to file
$output | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Source dump complete!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host ""
Write-Host "Output saved to: $OutputFile" -ForegroundColor Yellow
Write-Host "Total size: $([math]::Round((Get-Item $OutputFile).Length / 1KB, 2)) KB" -ForegroundColor Yellow
Write-Host ""
Write-Host "CRITICAL FILES TO VERIFY ARE INCLUDED:" -ForegroundColor Cyan
Write-Host "  - *.csproj (project configuration)" -ForegroundColor White
Write-Host "  - Program.cs (application startup)" -ForegroundColor White
Write-Host "  - wwwroot/index.html (entry point)" -ForegroundColor White
Write-Host "  - wwwroot/_headers (Cloudflare headers)" -ForegroundColor White
Write-Host "  - wwwroot/_redirects (Cloudflare redirects)" -ForegroundColor White
Write-Host "  - wwwroot/service-worker*.js (PWA)" -ForegroundColor White
Write-Host "  - build.sh or build.ps1 (build script)" -ForegroundColor White
Write-Host ""
Write-Host "Now paste this complete dump to Claude for full diagnosis!" -ForegroundColor Magenta