[System.Reflection.Assembly]::LoadFile("F:\.Repos\HGInstaller\HGInstaller.exe") | Out-Null

$testTarget = "F:\.Repos\HGInstaller\scratch_test_mc"
if (Test-Path $testTarget) { Remove-Item $testTarget -Recurse -Force }
New-Item -ItemType Directory -Path $testTarget -Force | Out-Null

$mainFormType = [HeroGuild.ClientInstaller.MainForm]

# 1. Test detection on empty versions folder
$mGetVersion = $mainFormType.GetMethod("GetInstalledFabricLoaderVersion", [System.Reflection.BindingFlags]"NonPublic,Static")
$resEmpty = $mGetVersion.Invoke($null, @($testTarget, "1.21.1"))
Write-Host "Test 1 (Empty folder):" ($resEmpty -eq $null) "(Expected True)"

# 2. Test detection on outdated Fabric 0.17.2
$fakeVerDir = Join-Path $testTarget "versions\fabric-loader-0.17.2-1.21.1"
New-Item -ItemType Directory -Path $fakeVerDir -Force | Out-Null
$fakeJson = '{"id":"fabric-loader-0.17.2-1.21.1","inheritsFrom":"1.21.1","mainClass":"net.fabricmc.loader.impl.launch.knot.KnotClient","libraries":[{"name":"net.fabricmc:fabric-loader:0.17.2"}]}'
[System.IO.File]::WriteAllText((Join-Path $fakeVerDir "fabric-loader-0.17.2-1.21.1.json"), $fakeJson)

$resOutdated = $mGetVersion.Invoke($null, @($testTarget, "1.21.1"))
Write-Host "Test 2 (Outdated 0.17.2):" $resOutdated "(Expected 0.17.2)"

# 3. Test detection on up to date Fabric 0.19.3
$fakeVerDir2 = Join-Path $testTarget "versions\fabric-loader-0.19.3-1.21.1"
New-Item -ItemType Directory -Path $fakeVerDir2 -Force | Out-Null
$fakeJson2 = '{"id":"fabric-loader-0.19.3-1.21.1","inheritsFrom":"1.21.1","mainClass":"net.fabricmc.loader.impl.launch.knot.KnotClient","libraries":[{"name":"net.fabricmc:fabric-loader:0.19.3"}]}'
[System.IO.File]::WriteAllText((Join-Path $fakeVerDir2 "fabric-loader-0.19.3-1.21.1.json"), $fakeJson2)

$resUpToDate = $mGetVersion.Invoke($null, @($testTarget, "1.21.1"))
Write-Host "Test 3 (Up to date 0.19.3):" $resUpToDate "(Expected 0.19.3)"

# Clean up
Remove-Item $testTarget -Recurse -Force
Write-Host "All detection tests completed successfully!"
