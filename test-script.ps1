# load module
. $psscriptroot\test-module.ps1


$testVersions = GetVersions
foreach ($version in $testVersions) {
    write-host "===== $version ====="

    write-host "=== remove environment if exists ==="
    RemoveEnv($version)
    
    write-host "=== setup environment ==="
    SetupEnv($version)
    
    write-host "=== install test package ==="
    if ($version -eq "3.13.0a2") {
        InstallPackage($version, $true)
    } else {
        InstallPackage($version)
    }
    
    write-host "=== run pytest ==="
    RunPytest($version)

    write-host ""

}
