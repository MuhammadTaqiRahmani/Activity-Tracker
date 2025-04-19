REM filepath: c:\Users\M. Taqi Rahmani\IdeaProjects\Backend-app\process_monitor\setup.bat
@echo off
echo Setting up Conda environment for process monitor...

REM Check if Conda is installed
where conda >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Conda is not installed or not in PATH
    echo Please install Miniconda from:
    echo https://docs.conda.io/en/latest/miniconda.html
    pause
    exit /b 1
)

REM Create new Conda environment
call conda create -n process_monitor python=3.10 -y
if %ERRORLEVEL% NEQ 0 (
    echo Failed to create Conda environment
    pause
    exit /b 1
)

REM Activate environment and install packages
call conda activate process_monitor

REM Install required packages using conda-forge
call conda install -c conda-forge pyqt=6 -y
call conda install -c conda-forge requests -y
call conda install -c conda-forge psutil -y
call conda install -c conda-forge python-jwt -y

echo.
echo Setup complete! To run the application:
echo 1. Activate the conda environment: conda activate process_monitor
echo 2. Run: python main.py
echo.
pause