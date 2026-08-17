[System.Reflection.Assembly]::LoadFile("F:\.Repos\HGInstaller\HGInstaller.exe") | Out-Null

$testTarget = "F:\.Repos\HGInstaller\scratch_test_mc_full"
if (Test-Path $testTarget) { Remove-Item $testTarget -Recurse -Force }
New-Item -ItemType Directory -Path $testTarget -Force | Out-Null

$mainForm = New-Object HeroGuild.ClientInstaller.MainForm
$mEnsure = [HeroGuild.ClientInstaller.MainForm].GetMethod("EnsureFabricLoaderInstalled", [System.Reflection.BindingFlags]"NonPublic,Instance")

$index = New-Object HeroGuild.ClientInstaller.ModrinthIndex
$index.dependencies = New-Object 'System.Collections.Generic.Dictionary[string,string]'
$index.dependencies["minecraft"] = "1.21.1"
$index.dependencies["fabric-loader"] = "0.19.3"

Write-Host "Running EnsureFabricLoaderInstalled..."
$mEnsure.Invoke($mainForm.psobject.BaseObject, [object[]]@($testTarget, $index.psobject.BaseObject))

$verJson = Join-Path $testTarget "versions\fabric-loader-0.19.3-1.21.1\fabric-loader-0.19.3-1.21.1.json"
$verJar = Join-Path $testTarget "versions\fabric-loader-0.19.3-1.21.1\fabric-loader-0.19.3-1.21.1.jar"
$profilesJson = Join-Path $testTarget "launcher_profiles.json"

Write-Host "Checking installed files:"
Write-Host " - fabric json exists:" (Test-Path $verJson)
Write-Host " - fabric jar exists:" (Test-Path $verJar)
Write-Host " - launcher_profiles.json exists:" (Test-Path $profilesJson)

if (Test-Path $profilesJson) {
    Write-Host "Content of launcher_profiles.json:"
    Get-Content $profilesJson
}

# Clean up
Remove-Item $testTarget -Recurse -Force
Write-Host ""
Write-Host "[SUCCESS] Full Fabric install test completed!" -ForegroundColor Green
