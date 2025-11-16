@echo off
REM AirSim UE 5.7 Build Verification Script for Windows
REM Run this script when UE 5.7 is installed

setlocal enabledelayedexpansion

echo =========================================
echo AirSim UE 5.7 Build Verification
echo =========================================
echo.

REM Configuration
set BUILD_CONFIGURATION=Development
set PLATFORM=Win64

REM Step 1: Check UE5 installation
echo [1/7] Checking UE 5.7 installation...

if "%UE5_ROOT%"=="" (
    echo ERROR: UE5_ROOT environment variable not set
    echo Please set UE5_ROOT to your Unreal Engine 5.7 installation directory
    echo Example: set UE5_ROOT=C:\Program Files\Epic Games\UE_5.7
    exit /b 1
)

if not exist "%UE5_ROOT%" (
    echo ERROR: UE5_ROOT directory does not exist: %UE5_ROOT%
    exit /b 1
)

if not exist "%UE5_ROOT%\Engine\Build\Build.version" (
    echo ERROR: Cannot find UE version file
    exit /b 1
)

echo ✓ Found Unreal Engine installation at %UE5_ROOT%

REM Step 2: Check Visual Studio
echo [2/7] Checking Visual Studio 2022...

where msbuild >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: MSBuild not found. Please run from Visual Studio Developer Command Prompt
    exit /b 1
)

echo ✓ MSBuild found

REM Step 3: Clean previous builds
echo [3/7] Cleaning previous builds...

if exist "%~dp0..\clean_rebuild.bat" (
    call "%~dp0..\clean_rebuild.bat"
    echo ✓ Clean complete
) else (
    echo WARNING: clean_rebuild.bat not found, skipping
)

REM Step 4: Check project file
echo [4/7] Checking project configuration...

set UPROJECT_FILE=%~dp0..\Unreal\Environments\Blocks\Blocks.uproject

if not exist "%UPROJECT_FILE%" (
    echo ERROR: Blocks.uproject not found at %UPROJECT_FILE%
    exit /b 1
)

findstr /C:"\"EngineAssociation\": \"5.7\"" "%UPROJECT_FILE%" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Project targets UE 5.7
) else (
    echo WARNING: Project may not target UE 5.7
)

REM Step 5: Generate project files
echo [5/7] Generating Visual Studio project files...

set UBT=%UE5_ROOT%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe

if not exist "%UBT%" (
    echo ERROR: UnrealBuildTool not found at %UBT%
    exit /b 1
)

"%UBT%" -projectfiles -project="%UPROJECT_FILE%" -game -rocket -progress
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to generate project files
    exit /b 1
)

echo ✓ Project files generated

REM Step 6: Build plugin
echo [6/7] Building AirSim Unreal plugin...

set BUILD_CMD=%UE5_ROOT%\Engine\Build\BatchFiles\Build.bat

if not exist "%BUILD_CMD%" (
    echo ERROR: Build script not found at %BUILD_CMD%
    exit /b 1
)

pushd "%~dp0..\Unreal\Environments\Blocks"

echo Running: "%BUILD_CMD%" Blocks %PLATFORM% %BUILD_CONFIGURATION% -project="%UPROJECT_FILE%"
call "%BUILD_CMD%" Blocks %PLATFORM% %BUILD_CONFIGURATION% -project="%UPROJECT_FILE%" > "%~dp0..\build_ue57.log" 2>&1

if %ERRORLEVEL% EQU 0 (
    echo ✓ Unreal plugin build SUCCEEDED
) else (
    echo ✗ Unreal plugin build FAILED
    echo Check build_ue57.log for details
    popd
    exit /b 1
)

popd

REM Step 7: Verify plugin
echo [7/7] Verifying plugin...

set PLUGIN_FILE=%~dp0..\Unreal\Plugins\AirSim\AirSim.uplugin

if exist "%PLUGIN_FILE%" (
    echo ✓ Plugin descriptor found
) else (
    echo ERROR: Plugin descriptor not found
    exit /b 1
)

REM Check for compiled binaries
set PLUGIN_BINARY_DIR=%~dp0..\Unreal\Plugins\AirSim\Binaries\Win64

if exist "%PLUGIN_BINARY_DIR%\*.dll" (
    echo ✓ Plugin binaries found
) else (
    echo WARNING: No DLL files found in %PLUGIN_BINARY_DIR%
)

echo.
echo =========================================
echo BUILD VERIFICATION COMPLETE
echo =========================================
echo.
echo Next steps:
echo 1. Open project in UE 5.7 Editor:
echo    "%UE5_ROOT%\Engine\Binaries\Win64\UnrealEditor.exe" "%UPROJECT_FILE%"
echo.
echo 2. Run Python API tests:
echo    python "%~dp0..\PythonClient\unreal_engine\ue57_compatibility_test.py"
echo.
echo 3. Check build log for warnings:
echo    type "%~dp0..\build_ue57.log"
echo.

endlocal
