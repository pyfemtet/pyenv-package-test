set-location $psscriptroot

# load module
. $psscriptroot\test-module.ps1

# detect python versions
# $installTestVersions = GetVersions
$installTestVersions = @("3.10.9", "3.11.7", "3.12.1")  # pyenv install --list | findstr
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
    $succeed = InstallPackage $version $true

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
