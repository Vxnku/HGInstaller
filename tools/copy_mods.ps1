$targetMods = @(
    "BetterGrassify-1.8.6+fabric.1.21.1.jar",
    "Debugify-1.21.1+1.0.jar",
    "ForgeConfigAPIPort-v21.1.6-1.21.1-Fabric.jar",
    "ImmediatelyFast-Fabric-1.6.10+1.21.1.jar",
    "Jade-1.21.1-Fabric-15.10.6.jar",
    "PuzzlesLib-v21.1.52-1.21.1-Fabric.jar",
    "QuickBinds-1.3.1-1.21.1.jar",
    "RoughlyEnoughItems-16.0.799-fabric.jar",
    "animatica-0.6.1+1.21.jar",
    "antighost-1.1.5-1.21.1.jar",
    "architectury-13.0.11-fabric.jar",
    "capes-1.5.4+1.21-fabric.jar",
    "citresewn-1.2.2+1.21.jar",
    "cloth-config-15.0.140-fabric.jar",
    "continuity-3.0.0+1.21.jar",
    "dynamic-fps-3.11.4+minecraft-1.21.0-fabric.jar",
    "emi-1.1.24+1.21.1+fabric.jar",
    "emotecraft-for-MC1.21.1-2.4.12-fabric.jar",
    "enhancedblockentities-0.10.2+1.21.jar",
    "entity_model_features-3.2.4-1.21-fabric.jar",
    "entity_texture_features_1.21-fabric-7.1.jar",
    "entityculling-fabric-1.10.2-mc1.21.1.jar",
    "fabric-api-0.116.12+1.21.1.jar",
    "fabric-language-kotlin-1.13.12+kotlin.2.4.0.jar",
    "fabricskyboxes-0.7.4+mc1.21.jar",
    "fastquit-3.0.0+1.20.6.jar",
    "ferritecore-7.0.3-fabric.jar",
    "fsb-interop-1.4.0+mc1.21-build.54.jar",
    "iris-fabric-1.8.8+mc1.21.1.jar",
    "lambdynamiclights-4.8.8+1.21.1.jar",
    "lithium-fabric-0.15.3+mc1.21.1.jar",
    "modelfix-1.21-1.6-fabric.jar",
    "modernfix-fabric-5.25.1+mc1.21.1.jar",
    "modmenu-11.0.4.jar",
    "moreculling-fabric-1.21.1-1.0.7.jar",
    "notenoughanimations-fabric-1.12.4-mc1.21.1.jar",
    "optigui-2.3.0-beta.9+1.21.jar",
    "plasmovoice-fabric-1.21.1-2.1.13.jar",
    "polytone-fabric-1.21-3.7.1.jar",
    "puzzle-fabric-2.3.0+1.21.1.jar",
    "reeses-sodium-options-fabric-1.8.3+mc1.21.4.jar",
    "sodium-extra-fabric-0.6.0+mc1.21.1.jar",
    "sodium-fabric-0.6.13+mc1.21.1.jar",
    "tooltipfix-1.1.1-1.20.jar",
    "walljump-1.21.1-1.3.8-fabric.jar",
    "xaerominimap-fabric-1.21.1-26.4.2.jar",
    "xaeroworldmap-fabric-1.21.1-1.44.2.jar",
    "yet_another_config_lib_v3-3.8.2+1.21.1-fabric.jar",
    "yosbr-0.1.2.jar"
)

$srcDir = "A:\MultiMC\instances\[FO][Fabric]1.21.1\.minecraft\mods"
$dstDir = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\.minecraft\mods"

if (-not (Test-Path -LiteralPath $dstDir)) {
    New-Item -ItemType Directory -LiteralPath $dstDir -Force | Out-Null
}

$copied = 0
foreach ($m in $targetMods) {
    $src = Join-Path $srcDir $m
    $dst = Join-Path $dstDir $m
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        $copied++
    } else {
        Write-Host "NOT FOUND: $m"
    }
}

Write-Host "Done! Successfully copied $copied / $($targetMods.Count) mods to $dstDir"
