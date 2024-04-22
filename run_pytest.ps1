# exit when error occured
$ErrorActionPreference = "Stop"

# debug
$ISDEBUG = $true

# repository setting
# note: the package must have dependency to pytest-dashboard
$repositoryName = "pyfemtet"

##### main #####


# config
$testroot = join-path $psscriptroot "test_root"
$jsonPath = join-path $testroot "environment_setup_result.json"

# move
cd $psscriptroot

# check setup is ran or not
if (-not (test-path($jsonPath))) {
    write-host $jsonPath is not found.
    write-host please run .\setup_pyenv_and_package.ps1 first.
    pause
    exit
}

# parse json
$jsonString = Get-Content -Raw -Path $jsonPath
$results = convertfrom-json $jsonString

# make dir to save progress file
if (-not (test-path("$testroot\progress"))) {mkdir $testroot\progress}


# run pytest in successfully set up environment
$total = $results.psobject.properties.name.count
$current = 0
foreach ($version in $results.psobject.properties.name)
{
    # write-progress
    $current++
    $percentComplete = ($current / $total) * 100
    Write-Progress -Activity "run pytest" -Status "env $current of $total" -PercentComplete $percentComplete

    # move to root
    cd $testroot

    # check environment succeed
    if (-not $results.$version) {continue}

    # move to environment
    cd $version\$repositoryName

    if ($ISDEBUG) {
        # pull
        git pull
        # re-install
        remove-item .\poetry.lock
        poetry install
    }

    # set $progressPath
    $progressPath = "$testroot\progress\$version-progress.yaml"

    # run_pytest via pytest-dashboard
    poetry run pytest .\tests\test_2_NoFEM --progress-path=$progressPath

    if ($ISDEBUG) {break}
    
}

if ($ISDEBUG) {pause}
