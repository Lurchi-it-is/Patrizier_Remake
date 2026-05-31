$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$version = (Get-Content -Raw "VERSION").Trim()
$requiredVersionFiles = @(
    "README.md",
    "CHANGELOG.md",
    "docs\PROJECT_PLAN.md",
    "docs\ARCHITECTURE.md",
    "docs\DEVELOPMENT.md",
    "project.godot"
)

foreach ($file in $requiredVersionFiles) {
    $content = Get-Content -Raw $file
    if (-not $content.Contains($version)) {
        throw "Version '$version' not found in $file"
    }
}

$jsonFiles = Get-ChildItem -Path "data" -Filter "*.json" -File
foreach ($jsonFile in $jsonFiles) {
    $raw = Get-Content -Raw $jsonFile.FullName
    $parsed = $raw | ConvertFrom-Json
    if ($null -eq $parsed) {
        throw "JSON file did not parse: $($jsonFile.FullName)"
    }
}

$goods = Get-Content -Raw "data\goods.json" | ConvertFrom-Json
$goodIds = @{}
foreach ($good in $goods) {
    $goodIds[$good.id] = $true
}

$cities = Get-Content -Raw "data\cities.json" | ConvertFrom-Json
foreach ($city in $cities) {
    foreach ($section in @("production", "consumption", "stock", "target_stock")) {
        $properties = $city.$section.PSObject.Properties
        foreach ($property in $properties) {
            if (-not $goodIds.ContainsKey($property.Name)) {
                throw "City '$($city.id)' references unknown good '$($property.Name)' in '$section'"
            }
        }
    }
}

$requiredPaths = @(
    "project.godot",
    "scenes\main.tscn",
    "scripts\main.gd",
    "scripts\data\catalog_loader.gd",
    "scripts\simulation\simulation_state.gd",
    "scripts\simulation\trade_price.gd",
    "scripts\simulation\combat_resolver.gd"
)

foreach ($path in $requiredPaths) {
    if (-not (Test-Path $path)) {
        throw "Required path missing: $path"
    }
}

$godotCandidates = @(
    "C:\Users\rje-m\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe",
    "godot",
    "godot4"
)

$godotCommand = $null
foreach ($candidate in $godotCandidates) {
    if (Test-Path -LiteralPath $candidate) {
        $godotCommand = $candidate
        break
    }

    $resolved = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($null -ne $resolved) {
        $godotCommand = $resolved.Source
        break
    }
}

if ($null -ne $godotCommand) {
    $godotOutput = & $godotCommand --headless --path . --quit 2>&1
    if ($LASTEXITCODE -ne 0 -or ($godotOutput -match "SCRIPT ERROR|ERROR:|Parse Error|Compile Error")) {
        $godotOutput | Write-Output
        throw "Godot headless validation failed"
    }
} else {
    Write-Warning "Godot executable not found; skipped engine validation"
}

Write-Output "Project validation passed for version $version"
