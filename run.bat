powershell -executionpolicy remotesigned -file .\setup_pyenv_and_package.ps1
start poetry run tally-pytest .\test_root\progress .\test_root\entire-progress.yaml --notification=True
powershell -executionpolicy remotesigned -file .\run_pytest.ps1
pause