rem powershell -executionpolicy remotesigned -file .\setup_pyenv_and_package.ps1
start poetry run python -m pytest_dashboard.tolly .\test_root\progress .\test_root\entire-progress.yaml
powershell -executionpolicy remotesigned -file .\run_pytest.ps1
pause