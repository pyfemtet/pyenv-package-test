# change shell encoding to utf-8 to correct install
chcp 65001

# exit when error occured
$ErrorActionPreference = "Stop"

# debug
$ISDEBUG = $true

# repository setting
$repositoryName = "pyfemtet"
$repositoryURL = "https://github.com/pyfemtet/pyfemtet.git"


##### main #####

# root
$testroot = join-path $psscriptroot test_root
if (test-path $testroot) {
    cd $psscriptroot
    remove-item $testroot -recurse -force -verbose
}
mkdir $testroot

# cd
cd $testroot

# pyenv install --list
write-host searching available python versions via pyenv...
$availableVersions = pyenv install --list

# pyenv installed version
write-host collecting installed python versions via pyenv...
$installedVersions = pyenv versions

# detect stable versions
write-host detecting python 3.9.0 or later stable versions to test $repositoryname...
$stableVersions = @()
foreach ($availableVersion in $availableVersions)
{
    if ($availableVersion -match "\d*\.\d*\.\d*$") {

        # 3.9.0 or later
        $buff = ([string]$availableVersion).split(".")
        $major = [int]($buff[0])
        $minor = [int]($buff[1])
        $bugfix = [int]($buff[2])
        $v = $major * 10000 + $minor * 100 + $bugfix
        if ($v -ge 30900) {
            write-host python $availableVersion will be tested
            $stableVersions += $availableVersion
            if ($ISDEBUG) {break}
        }
    }
}

# install if not installed
foreach ($stableVersion in $stableVersions) {
    if (-not ([string]$installedVersions).contains($stableVersion)) {
        write-host installing $stableVersion...
        pyenv install $stableVersion
    }
}

# run test
$results = @{}

# create directory its name is same as version name
foreach ($stableVersion in $stableVersions)
{
    # move to rootdir
    cd $testroot

    # mkdir
    if (-not (test-path $stableVersion)) {mkdir $stableVersion}
        
    # move to made dir and set local interpreter
    cd $stableVersion

    # git clone [repositoryURL]
    write-host cloning $repositoryURL...
    if (-not (test-path $repositoryName)) {git clone $repositoryURL --quiet}

    # move to local repository
    cd $repositoryName

    # switch and checkout branch "dev"
    write-host checking out dev branch...
    git checkout dev --quiet

    # set python interpreter
    pyenv local $stableVersion
    start-sleep 3

    # poetry env setting
    write-host try to create venv via poetry
    poetry config --local virtualenvs.in-project true
    if ($ISDEBUG) {read-host edit pyproject.toml}
    poetry env use python --quiet

    # env is NA if the package does not support the version
    # -> test failed
    $p = poetry env info --path
    if ($p -eq $null) {
        write-host $stableVersion is not supported.
        $results.add($stableVersion, $false)

        if ($ISDEBUG) {break}

        continue
    }

    <#
    # install package
    write-host try to install $repositoryName in $stableVersion
    remove-item .\poetry.lock
    poetry install --without=dev

    # no .lock file if install failed
    # -> test failed
    if (-not (test-path poetry.lock)) {
        write-host $stableVersion failed to install $repositoryName.
        $results.add($stableVersion, $false)

        if ($ISDEBUG) {break}

        continue
    }
    #>

    # successfully environment set up
    $results.add($stableVersion, $true)

    if ($ISDEBUG) {break}
}

# move to root
cd $testroot

# save result
$results | ConvertTo-Json | Out-File "environment_setup_result.json" -Encoding UTF8
