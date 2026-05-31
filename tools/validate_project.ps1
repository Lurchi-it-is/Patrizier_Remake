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
    if ($goodIds.ContainsKey($good.id)) {
        throw "Duplicate good id '$($good.id)'"
    }

    if ($null -eq $good.unit) {
        throw "Good '$($good.id)' is missing historical unit metadata"
    }

    foreach ($field in @("name", "abbreviation", "basis")) {
        if ([string]::IsNullOrWhiteSpace([string]$good.unit.$field)) {
            throw "Good '$($good.id)' unit is missing '$field'"
        }
    }

    $goodIds[$good.id] = $true
}

$populationGroups = Get-Content -Raw "data\population_groups.json" | ConvertFrom-Json
$populationGroupIds = @{}
foreach ($group in $populationGroups) {
    if ($populationGroupIds.ContainsKey($group.id)) {
        throw "Duplicate population group id '$($group.id)'"
    }

    $populationGroupIds[$group.id] = $true
    foreach ($need in $group.daily_consumption_per_1000.PSObject.Properties) {
        if (-not $goodIds.ContainsKey($need.Name)) {
            throw "Population group '$($group.id)' references unknown good '$($need.Name)'"
        }
    }
}

$cities = Get-Content -Raw "data\cities.json" | ConvertFrom-Json
$cityEconomyReports = @()
$regionalProduction = @{}
$regionalConsumption = @{}
foreach ($city in $cities) {
    $dailyConsumption = @{}
    foreach ($section in @("production", "consumption", "stock", "target_stock")) {
        $properties = $city.$section.PSObject.Properties
        foreach ($property in $properties) {
            if (-not $goodIds.ContainsKey($property.Name)) {
                throw "City '$($city.id)' references unknown good '$($property.Name)' in '$section'"
            }

            if ($section -eq "consumption") {
                $dailyConsumption[$property.Name] = [double]$property.Value
            }

            if ($section -eq "production") {
                if (-not $regionalProduction.ContainsKey($property.Name)) {
                    $regionalProduction[$property.Name] = 0.0
                }

                $regionalProduction[$property.Name] += [double]$property.Value
            }
        }
    }

    if ($city.production.PSObject.Properties.Count -eq 0) {
        throw "City '$($city.id)' has no production profile"
    }

    if ($city.consumption.PSObject.Properties.Count -eq 0) {
        throw "City '$($city.id)' has no consumption profile"
    }

    $groupPopulation = 0
    foreach ($groupProperty in $city.population_groups.PSObject.Properties) {
        if (-not $populationGroupIds.ContainsKey($groupProperty.Name)) {
            throw "City '$($city.id)' references unknown population group '$($groupProperty.Name)'"
        }

        $groupPopulation += [int]$groupProperty.Value
        $group = $populationGroups | Where-Object { $_.id -eq $groupProperty.Name } | Select-Object -First 1
        foreach ($need in $group.daily_consumption_per_1000.PSObject.Properties) {
            if (-not $dailyConsumption.ContainsKey($need.Name)) {
                $dailyConsumption[$need.Name] = 0.0
            }

            $dailyConsumption[$need.Name] += ([double]$groupProperty.Value / 1000.0) * [double]$need.Value
        }
    }

    if ($groupPopulation -ne [int]$city.population) {
        throw "City '$($city.id)' population_groups sum $groupPopulation does not match population $($city.population)"
    }

    foreach ($goodId in $dailyConsumption.Keys) {
        if (-not ($city.target_stock.PSObject.Properties.Name -contains $goodId)) {
            throw "City '$($city.id)' has no target_stock for consumed good '$goodId'"
        }

        if (-not $regionalConsumption.ContainsKey($goodId)) {
            $regionalConsumption[$goodId] = 0.0
        }

        $regionalConsumption[$goodId] += [double]$dailyConsumption[$goodId]
    }

    $productionGoods = ($city.production.PSObject.Properties | Where-Object { [double]$_.Value -gt 0 }).Count
    $consumptionGoods = ($dailyConsumption.GetEnumerator() | Where-Object { [double]$_.Value -gt 0 }).Count
    $cityEconomyReports += "City economy '$($city.id)': $productionGoods produced goods, $consumptionGoods consumed goods, population groups $groupPopulation/$($city.population)"
}

$cityEconomyReports | Write-Output

foreach ($goodId in $regionalConsumption.Keys) {
    $produced = [double]$regionalProduction.Get_Item($goodId)
    $consumed = [double]$regionalConsumption[$goodId]
    if ($produced -lt $consumed) {
        throw "Regional production/supply for good '$goodId' is below daily consumption: $produced < $consumed"
    }
}

$requiredPaths = @(
    "export_presets.cfg",
    "project.godot",
    "scenes\main.tscn",
    "scenes\launcher.tscn",
    "scenes\main_game.tscn",
    "scenes\map_editor.tscn",
    "scripts\main.gd",
    "scripts\launcher.gd",
    "scripts\main_game.gd",
    "scripts\map_editor.gd",
    "scripts\data\catalog_loader.gd",
    "scripts\simulation\simulation_state.gd",
    "scripts\simulation\trade_price.gd",
    "scripts\simulation\combat_resolver.gd",
    "scripts\ui\map_view.gd"
)

foreach ($path in $requiredPaths) {
    if (-not (Test-Path $path)) {
        throw "Required path missing: $path"
    }
}

$projectSettings = Get-Content -Raw "project.godot"
if (-not $projectSettings.Contains('run/main_scene="res://scenes/launcher.tscn"')) {
    throw "Project main scene must be the launcher scene"
}

$exportPresets = Get-Content -Raw "export_presets.cfg"
foreach ($requiredPresetText in @(
    'name="Windows Main Game"',
    'custom_features="main_game"',
    'export_path="builds/HanseMainGame.exe"',
    'name="Windows Map Editor"',
    'custom_features="map_editor"',
    'export_path="builds/HanseMapEditor.exe"'
)) {
    if (-not $exportPresets.Contains($requiredPresetText)) {
        throw "Export preset missing required entry: $requiredPresetText"
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
    $importOutput = & $godotCommand --headless --editor --path . --quit 2>&1
    if ($LASTEXITCODE -ne 0 -or ($importOutput -match "SCRIPT ERROR|ERROR:|Parse Error|Compile Error")) {
        $importOutput | Write-Output
        throw "Godot asset import failed"
    }

    $godotOutput = & $godotCommand --headless --path . --quit 2>&1
    if ($LASTEXITCODE -ne 0 -or ($godotOutput -match "SCRIPT ERROR|ERROR:|Parse Error|Compile Error")) {
        $godotOutput | Write-Output
        throw "Godot headless validation failed"
    }
} else {
    Write-Warning "Godot executable not found; skipped engine validation"
}

Write-Output "Project validation passed for version $version"
