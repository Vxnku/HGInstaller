Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead('A:\MultiMC\instances\[HG][Fabric 1.21.1]\[HG][Fabric 1.21.1].mrpack')
$zip.Entries | Select-Object -Property FullName, Length
$zip.Dispose()
