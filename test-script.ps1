# load module
. $psscriptroot\test-module.ps1

# detect python versions
$installTestVersions = GetVersions
$testVersions = @()

# package install test
foreach ($version in $installTestVersions) {
    write-host ""
    write-host "===== $version ====="

    write-host "=== remove environment if exists ==="
    RemoveEnv($version)
    
    write-host "=== setup environment ==="
    SetupEnv($version)
    
    write-host "=== install test package ==="
    if ($version -eq "3.13.0a2") {
        $succeed = InstallPackage $version $true
    } else {
        $succeed = InstallPackage $version
    }

    if ($succeed) {
        write-host "=== collect test cases ==="
        $testVersions += $version
        RunPytest $version $true
    } else {
        write-host "=== skip test ==="
    }

    write-host ""

}

# start tally process
Set-Location $PSScriptRoot
$argumentlist = "$PROGRESS_FOLDER --entire_progress_path $ENTIRE_PROGRESS"
Start-Process -FilePath "test-tally.bat" -WindowStyle Normal -ArgumentList $argumentlist

# package test
foreach ($version in $testVersions) {
    write-host "===== $version ====="

    write-host "=== run pytest ==="
    RunPytest $version

    write-host ""

}
