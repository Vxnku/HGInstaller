try {
    $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=HeroGuild Client Installer, O=HeroGuild, C=RU" -CertStoreLocation "Cert:\CurrentUser\My" -FriendlyName "HeroGuild Code Signing"
    Write-Host "Created certificate: $($cert.Thumbprint)"
    
    $exePath = "A:\MultiMC\instances\[HG][Fabric 1.21.1]\installer\HGInstaller.exe"
    $sig = Set-AuthenticodeSignature -FilePath $exePath -Certificate $cert -HashAlgorithm SHA256
    Write-Host "Signature status: $($sig.Status)"
} catch {
    Write-Host "Error: $_"
}
