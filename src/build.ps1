# PowerShell build script for HeroGuild Client Installer
$ErrorActionPreference = "Stop"
$srcDir = $PSScriptRoot
$outExe = Join-Path $srcDir "..\HGInstaller.exe"
$outExe = [System.IO.Path]::GetFullPath($outExe)

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Building HeroGuild Client Installer (x64 Clean Build)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# Ensure UTF-8 with BOM on source files so compilers never corrupt Cyrillic
$csFiles = @("AssemblyInfo.cs", "HGInstaller.cs")
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
foreach ($f in $csFiles) {
    $p = Join-Path $srcDir $f
    if (Test-Path $p) {
        $content = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($p, $content, $utf8Bom)
    }
}

$dotnetCmd = Get-Command "dotnet" -ErrorAction SilentlyContinue
if ($null -ne $dotnetCmd) {
    Write-Host "[*] Using modern Roslyn compiler (dotnet SDK)..." -ForegroundColor Yellow
    $csprojPath = Join-Path $srcDir "HGInstaller.csproj"
    $csprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net48</TargetFramework>
    <AssemblyName>HGInstaller</AssemblyName>
    <ApplicationIcon>app.ico</ApplicationIcon>
    <ApplicationManifest>app.manifest</ApplicationManifest>
    <UseWindowsForms>true</UseWindowsForms>
    <GenerateAssemblyInfo>false</GenerateAssemblyInfo>
    <DebugType>embedded</DebugType>
    <Optimize>true</Optimize>
    <PlatformTarget>x64</PlatformTarget>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="AssemblyInfo.cs" />
    <Compile Include="HGInstaller.cs" />
    <EmbeddedResource Include="logo.png" LogicalName="HGLogo.png" />
    <EmbeddedResource Include="discord.png" LogicalName="DiscordLogo.png" />
  </ItemGroup>
  <ItemGroup>
    <Reference Include="System.Net.Http" />
    <Reference Include="System.Web.Extensions" />
    <Reference Include="System.IO.Compression" />
    <Reference Include="System.IO.Compression.FileSystem" />
  </ItemGroup>
</Project>
"@
    [System.IO.File]::WriteAllText($csprojPath, $csprojContent, $utf8Bom)
    & dotnet build $csprojPath -c Release -o (Join-Path $srcDir "bin\Release") --nologo
    if ($LASTEXITCODE -eq 0) {
        Copy-Item (Join-Path $srcDir "bin\Release\HGInstaller.exe") $outExe -Force
    } else {
        Write-Error "dotnet build failed!"
        exit 1
    }
} else {
    Write-Host "[!] dotnet SDK not found, falling back to csc.exe (x64)..." -ForegroundColor Yellow
    $csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    if (-not (Test-Path $csc)) {
        $csc = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
    }

    $icoPath = Join-Path $srcDir "app.ico"
    $manifestPath = Join-Path $srcDir "app.manifest"
    $logoPath = Join-Path $srcDir "logo.png"
    $discordPath = Join-Path $srcDir "discord.png"
    $assemblyInfo = Join-Path $srcDir "AssemblyInfo.cs"
    $mainCs = Join-Path $srcDir "HGInstaller.cs"

    & $csc /target:winexe /optimize+ /platform:x64 /debug:pdbonly /utf8output /win32icon:"$icoPath" /win32manifest:"$manifestPath" /resource:"$logoPath,HGLogo.png" /resource:"$discordPath,DiscordLogo.png" /r:System.Net.Http.dll /r:System.Web.Extensions.dll /r:System.IO.Compression.dll /r:System.IO.Compression.FileSystem.dll /r:System.Windows.Forms.dll /r:System.Drawing.dll /out:"$outExe" "$assemblyInfo" "$mainCs"
}

if (Test-Path $outExe) {
    # Self-sign the executable to populate the PE Certificate Table (reduces ML false positives)
    try {
        Write-Host "[*] Applying Authenticode signature..." -ForegroundColor Yellow
        $cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.Subject -match "HeroGuild" } | Select-Object -First 1
        if ($null -eq $cert) {
            $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=HeroGuild Community" -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(5)
        }
        Set-AuthenticodeSignature -FilePath $outExe -Certificate $cert -HashAlgorithm SHA256 | Out-Null
        Write-Host "[+] Digital signature applied successfully!" -ForegroundColor Green
    } catch {
        Write-Host "[i] Could not apply self-signed certificate: $($_.Exception.Message)" -ForegroundColor DarkGray
    }

    $fi = Get-Item $outExe
    $kb = [math]::Round($fi.Length / 1024, 2)
    Write-Host ""
    Write-Host "[SUCCESS] HGInstaller.exe compiled successfully!" -ForegroundColor Green
    Write-Host "Size: $($fi.Length) bytes ($kb KB)" -ForegroundColor Green
    Write-Host "Output: $($fi.FullName)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Compilation failed." -ForegroundColor Red
}
