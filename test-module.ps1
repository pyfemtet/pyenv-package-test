# change shell encoding to utf-8 to correct install
chcp 65001

# Stop when error
$ErrorActionPreference = "Stop"

# config
$jsonFilePath = join-path $psscriptroot "test-config.json"
$jsonContent = Get-Content -Raw -Path $jsonFilePath | ConvertFrom-Json
$REPOSITORY_URL = $jsonContent.REPOSITORY_URL
$PACKAGE_NAME = $jsonContent.PACKAGE_NAME
$TEST_BRANCH = $jsonContent.TEST_BRANCH
$TEST_ROOT = $jsonContent.TEST_ROOT
$PROGRESS_FOLDER = $jsonContent.PROGRESS_FOLDER
$INCLUDE_VERSIONS = $jsonContent.INCLUDE_VERSIONS
$EXCLUDE_VERSIONS = $jsonContent.EXCLUDE_VERSIONS
$PYTEST_ARGUMENTS = $jsonContent.PYTEST_ARGUMENTS

# set-location to root
Set-Location $psscriptroot
if ( -not (Test-Path $TEST_ROOT)) {New-Item -ItemType Directory -Path $TEST_ROOT}
if ( -not (Test-Path $PROGRESS_FOLDER)) {New-Item -ItemType Directory -Path $PROGRESS_FOLDER}
$TEST_ROOT = Convert-Path $TEST_ROOT
$PROGRESS_FOLDER = Convert-Path $PROGRESS_FOLDER
Set-Location $TEST_ROOT


function RemoveEnv {
    param(
        [string]$version
    )
    
    $location = Join-Path $TEST_ROOT $version
    
    if (Test-Path $location) {
        Remove-Item -Path $location -Recurse -Force
    }

    Set-Location $TEST_ROOT
}

function SetupEnv {
    param(
        [string]$version
    )
    
    $location = Join-Path $TEST_ROOT $version
    New-Item -ItemType Directory -Path $location
    
    pyenv install $version

    Set-Location $TEST_ROOT
    return $true
}

function InstallPackage {
    param(
        [string]$version,
        [bool]$extendPythonVersion = $false
    )
    
    $location = Join-Path $TEST_ROOT $version

    # clone repository
    Set-Location $location
    git clone $REPOSITORY_URL --quiet
   
    # set python version to repository
    Set-Location $PACKAGE_NAME
    pyenv local $version
    git checkout $TEST_BRANCH --quiet
    poetry config --local virtualenvs.in-project true

    # extend python version
    if ($extendPythonVersion) {
        $tomlPath = "pyproject.toml"
        $content = Get-Content -Path $tomlPath | ForEach-Object {
            if ($_ -match "^\s*python\s*=") {
                $replacedLine = 'python = ">3.9.2, <=' + $version + '"'
                $_ -replace '^\s*python\s*=.*', $replacedLine
            } else {
                $_
            }
        }
        $content | Set-Content -Path $tomlPath
    }

    # create virtualenv
    poetry env use python --quiet
   
    # virtual environment is NA if the package does not support the version
    $p = poetry env info --path
    if ($null -eq $p) {
        write-host "$version is not supported by $PACKAGE_NAME."

        Set-Location $TEST_ROOT
        return $false
    }

    # install package to test
    remove-item .\poetry.lock
    poetry install --no-interaction --no-cache
   
    # no .lock file if install failed
    # -> test failed
    if (-not (test-path poetry.lock)) {
        write-host "$version failed to install $PACKAGE_NAME."

        Set-Location $TEST_ROOT
        return $true
    }

    Set-Location $TEST_ROOT
    return $true
}

function RunPytest {
    param(
        [string]$version,
        [bool]$collectOnly=$false
    )

    Set-Location $TEST_ROOT
    if ( -not($PROGRESS_FOLDER)) {New-Item -ItemType Directory $PROGRESS_FOLDER}

    $location = Join-Path $TEST_ROOT $version
    Set-Location $location
    Set-Location $PACKAGE_NAME
    $yamlPath = Join-Path $PROGRESS_FOLDER "$version-progress.yaml"
    ExecPyTest $yamlPath $collectOnly

    Set-Location $TEST_ROOT
    return $null
}

function ExecPyTest {
    param(
        [string]$yamlPath,
        [bool]$collectOnly
    )
    if ($collectOnly) {
        poetry run pytest $PYTEST_ARGUMENTS --progress-path=$yamlPath --collect-only
    } else {
        poetry run pytest $PYTEST_ARGUMENTS --progress-path=$yamlPath
    }
}

function GetVersions {
    # pyenv install --list
    write-host "searching available python versions via pyenv..."
    $availableVersions = pyenv install --list

    # detect stable versions
    write-host "detecting python 3.9.0 or later stable versions to test $PACKAGE_NAME..."
    $stableVersions = @()
    foreach ($availableVersion in $availableVersions)
    {
        # extract stable versions
        if ($availableVersion -match "\d*\.\d*\.\d*$") {

            # extract 3.9.0 or later
            $buff = ([string]$availableVersion).split(".")
            $major = [int]($buff[0])
            $minor = [int]($buff[1])
            $bugfix = [int]($buff[2])
            $v = $major * 10000 + $minor * 100 + $bugfix
            if ($v -ge 30900) {

                if ($EXCLUDE_VERSIONS -contains $availableVersion) {
                    write-host "$availableVersion is excepted exceptionally"
                } else {
                    write-host "$availableVersion will be tested"
                    $stableVersions += $availableVersion
                }
            }
        } else {
            # include unstable versions exceptionally
            if ($INCLUDE_VERSIONS -contains $availableVersion) {
                write-host "$availableVersion will be tested exceptionally"
                $stableVersions += $availableVersion
            }
        }
    }

    return $stableVersions
}
