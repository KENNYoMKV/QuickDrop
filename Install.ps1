param(
    [string]$GameRoot = 'C:\Games\ReSkate-1.0.0',
    [switch]$Uninstall
)
$ErrorActionPreference = 'Stop'
$rootPath = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$running = @(Get-Process Skate,ReSkateLauncher -ErrorAction SilentlyContinue | Where-Object {
    !$_.Path -or [IO.Path]::GetDirectoryName($_.Path) -eq $rootPath
})
if ($running.Count) { throw 'Close skate. and the ReSkate launcher for this game folder before installing or removing the native companion.' }
$dll = Join-Path $GameRoot 'ReSkate.dll'
$mod = Join-Path $GameRoot 'Mods\Dynamic_QuickDrop'
$settingsPath = Join-Path $GameRoot 'ReSkateLauncher.settings.json'
$backupRoot = Join-Path $GameRoot 'DynamicQuickDrop-backup'
$recordPath = Join-Path $backupRoot 'installed.json'
$favoritesRecordPath = Join-Path $GameRoot 'QuickDropFavorites-backup\installed.json'
$modsPath = Join-Path $GameRoot 'Mods\mods.json'
function Write-Json($path, $value) {
    [IO.File]::WriteAllText($path, ($value | ConvertTo-Json -Depth 32), [Text.UTF8Encoding]::new($false))
}
function Read-ModSettings {
    if (Test-Path $modsPath) { return Get-Content -Raw $modsPath | ConvertFrom-Json }
    return [pscustomobject]@{schema=1; mods=@()}
}
function Set-ModEntries($names, $entries) {
    $settings = Read-ModSettings
    $kept = @($settings.mods | Where-Object { $_.name -notin $names })
    $settings | Add-Member -NotePropertyName mods -NotePropertyValue @($kept + @($entries)) -Force
    Write-Json $modsPath $settings
}
function Set-LauncherUpdates([bool]$enabled) {
    $settings = Get-Content -Raw $settingsPath | ConvertFrom-Json
    $settings | Add-Member -NotePropertyName updates -NotePropertyValue $enabled -Force
    [IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 32), [Text.UTF8Encoding]::new($false))
}
if ($Uninstall) {
    if (!(Test-Path $recordPath)) { throw 'No Dynamic QuickDrop native installation record found.' }
    $record = Get-Content -Raw $recordPath | ConvertFrom-Json
    if ((Get-FileHash $dll -Algorithm SHA256).Hash.ToLowerInvariant() -ne $record.installed_dll) {
        throw 'ReSkate.dll has changed since installation. Your original DLL is in DynamicQuickDrop-backup; preserve the newer runtime before restoring.'
    }
    if (Test-Path $mod) {
        # Preserve any changes made to the installed mod, too.
        Move-Item $mod (Join-Path $record.backup ('removed-Dynamic_QuickDrop-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff')))
    }
    Copy-Item (Join-Path $record.backup 'ReSkate.dll') $dll -Force
    if ($record.had_mod) { Copy-Item (Join-Path $record.backup 'Dynamic_QuickDrop') $mod -Recurse }
    if ($record.had_launcher_settings -and (Test-Path $settingsPath)) {
        Set-LauncherUpdates ([bool]$record.launcher_updates)
    }
    if ($record.schema -eq 2) {
        foreach ($name in $record.legacy_favorites_folders) {
            $destination = Join-Path (Join-Path $GameRoot 'Mods') $name
            if (Test-Path $destination) {
                Move-Item $destination (Join-Path $record.backup ('later-' + $name + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff')))
            }
            Copy-Item (Join-Path (Join-Path $record.backup 'legacy-mods') $name) $destination -Recurse
        }
        Set-ModEntries $record.mod_names $record.previous_mod_entries
        if (!$record.had_mods_settings -and @((Read-ModSettings).mods).Count -eq 0) { Remove-Item $modsPath }
        if ($record.had_favorites_installation) {
            Copy-Item (Join-Path $record.backup 'previous-favorites-installed.json') $favoritesRecordPath -Force
        }
    }
    Move-Item $recordPath (Join-Path $record.backup 'uninstalled.json')
    if ($record.had_previous_installation) {
        Copy-Item (Join-Path $record.backup 'previous-dynamic-installed.json') $recordPath
    }
    Write-Output 'Restored the previous runtime and QuickDrop installation. Backups and saved favorites retained.'
    return
}
$exe = Join-Path $GameRoot 'Skate.exe'
if (!(Test-Path $dll) -or !(Test-Path $exe)) { throw 'Choose the ReSkate game directory with -GameRoot.' }
if ((Get-FileHash $exe -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'fbce74d5e28ef525dbba2cb4adbebc13405bdbd88f31bc940bca45e4ae88b8f9') {
    throw 'This native preview supports only skate. build 25414733.'
}
if ((Get-Item $dll).VersionInfo.ProductVersion -notlike '2.1.1*') { throw 'This native preview is based on ReSkate 2.1.1.' }
$manifest = Get-Content -Raw (Join-Path $PSScriptRoot 'native-validation.json') | ConvertFrom-Json
foreach ($file in $manifest.package_files.PSObject.Properties) {
    $path = Join-Path $PSScriptRoot $file.Name
    if (!(Test-Path $path) -or (Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $file.Value) {
        throw "Package checksum mismatch: $($file.Name)"
    }
}
$hadPrevious = Test-Path $recordPath
$hadFavorites = Test-Path $favoritesRecordPath
$previous = $null
$favorites = $null
if ($hadPrevious) { $previous = Get-Content -Raw $recordPath | ConvertFrom-Json }
if ($hadFavorites) { $favorites = Get-Content -Raw $favoritesRecordPath | ConvertFrom-Json }
$currentHash = (Get-FileHash $dll -Algorithm SHA256).Hash.ToLowerInvariant()
if ($hadFavorites) {
    if ($currentHash -ne $favorites.installed_dll) { throw 'Runtime changed since Favorites installation. Preserve that runtime before upgrading.' }
    if ($hadPrevious -and (Get-FileHash (Join-Path $favorites.backup 'ReSkate.dll')).Hash -ne $previous.installed_dll) {
        throw 'The Favorites and Dynamic QuickDrop backup chain does not match.'
    }
} elseif ($hadPrevious -and $currentHash -ne $previous.installed_dll) {
    throw 'Runtime changed since Dynamic QuickDrop installation. Preserve that runtime before upgrading.'
}
$legacyFolders = @()
foreach ($folder in Get-ChildItem (Join-Path $GameRoot 'Mods') -Directory -ErrorAction SilentlyContinue) {
    $legacyManifest = Join-Path $folder.FullName 'manifest.json'
    if (Test-Path $legacyManifest) {
        try { $legacy = Get-Content -Raw $legacyManifest | ConvertFrom-Json } catch { continue }
        if ($legacy.name -eq 'QuickDrop Favorites') { $legacyFolders += $folder.Name }
    }
}
$modNames = @('Dynamic_QuickDrop') + $legacyFolders
$oldModSettings = Read-ModSettings
$oldEntries = @($oldModSettings.mods | Where-Object { $_.name -in $modNames })
$hadModsSettings = Test-Path $modsPath
$backup = Join-Path $backupRoot (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
New-Item -ItemType Directory -Path $backup -Force | Out-Null
Copy-Item $dll (Join-Path $backup 'ReSkate.dll')
$hadMod = Test-Path $mod
if ($hadMod) { Copy-Item $mod (Join-Path $backup 'Dynamic_QuickDrop') -Recurse }
if ($hadPrevious) { Copy-Item $recordPath (Join-Path $backup 'previous-dynamic-installed.json') }
if ($hadFavorites) { Copy-Item $favoritesRecordPath (Join-Path $backup 'previous-favorites-installed.json') }
if ($hadModsSettings) { Copy-Item $modsPath (Join-Path $backup 'mods.json') }
if ($legacyFolders.Count) {
    New-Item -ItemType Directory -Path (Join-Path $backup 'legacy-mods') | Out-Null
    foreach ($name in $legacyFolders) {
        Copy-Item (Join-Path (Join-Path $GameRoot 'Mods') $name) (Join-Path (Join-Path $backup 'legacy-mods') $name) -Recurse
    }
}
$hadSettings = Test-Path $settingsPath
$updates = $true
if ($hadSettings) {
    Copy-Item $settingsPath (Join-Path $backup 'ReSkateLauncher.settings.json')
    $settings = Get-Content -Raw $settingsPath | ConvertFrom-Json
    if ($null -ne $settings.updates) { $updates = [bool]$settings.updates }
}
$record = @{ schema=2; backup=$backup; had_mod=$hadMod; installed_dll=$manifest.package_files.'Runtime/ReSkate.dll';
             had_launcher_settings=$hadSettings; launcher_updates=$updates;
             had_previous_installation=$hadPrevious; had_favorites_installation=$hadFavorites;
             legacy_favorites_folders=$legacyFolders; mod_names=$modNames; previous_mod_entries=$oldEntries;
             had_mods_settings=$hadModsSettings }
try {
    if ($hadSettings) { Set-LauncherUpdates $false }
    if ($hadMod) { Remove-Item $mod -Recurse -Force }
    New-Item -ItemType Directory -Path (Split-Path $mod -Parent) -Force | Out-Null
    Copy-Item (Join-Path $PSScriptRoot 'Dynamic_QuickDrop') $mod -Recurse
    Copy-Item (Join-Path $PSScriptRoot 'Runtime\ReSkate.dll') $dll -Force
    foreach ($name in $legacyFolders) { Remove-Item (Join-Path (Join-Path $GameRoot 'Mods') $name) -Recurse -Force }
    if ($hadFavorites) { Remove-Item $favoritesRecordPath }
    Set-ModEntries $modNames @([pscustomobject]@{name='Dynamic_QuickDrop'; enabled=$true})
    Write-Json $recordPath $record
} catch {
    Copy-Item (Join-Path $backup 'ReSkate.dll') $dll -Force
    if (Test-Path $mod) { Remove-Item $mod -Recurse -Force }
    if ($hadMod) { Copy-Item (Join-Path $backup 'Dynamic_QuickDrop') $mod -Recurse }
    if ($hadSettings) { Copy-Item (Join-Path $backup 'ReSkateLauncher.settings.json') $settingsPath -Force }
    if ($hadModsSettings) { Copy-Item (Join-Path $backup 'mods.json') $modsPath -Force }
    elseif (Test-Path $modsPath) { Remove-Item $modsPath }
    foreach ($name in $legacyFolders) {
        $destination = Join-Path (Join-Path $GameRoot 'Mods') $name
        if (!(Test-Path $destination)) { Copy-Item (Join-Path (Join-Path $backup 'legacy-mods') $name) $destination -Recurse }
    }
    if ($hadFavorites) { Copy-Item (Join-Path $backup 'previous-favorites-installed.json') $favoritesRecordPath -Force }
    if ($hadPrevious) { Copy-Item (Join-Path $backup 'previous-dynamic-installed.json') $recordPath -Force }
    elseif (Test-Path $recordPath) { Remove-Item $recordPath }
    throw
}
Write-Output 'Installed and enabled one Dynamic_QuickDrop mod. Insert > Addons > Dynamic QuickDrop > Physics / Marker / Favorites.'
Write-Output 'Existing favorites and physics preferences are preserved. Standalone Favorites files and installation records are archived in the backup.'
Write-Output 'Keep launcher runtime updates OFF while testing: an update replaces this custom DLL. The previous update setting is restored on uninstall.'
Write-Output "Original files retained in $backup"
