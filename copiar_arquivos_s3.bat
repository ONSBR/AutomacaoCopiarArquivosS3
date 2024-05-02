@echo off
setlocal enabledelayedexpansion

:: Define o bucket S3, prefixo do caminho, diretório fonte e caminhos dos diretórios arquivos de sinalizacao e de logs de erros.
set "bucket=###enter-bucket-name-here###"
set "pathPrefix=###enter-path-prefix-here###"
set "sourceDir=###enter-source-dir-here###"

set "flagDir=%sourceDir%flags"
set "errorLogDir=%sourceDir%erros"

set "timestamp=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%h%time:~3,2%m%time:~6,2%s"
set "errorFilePath=%errorLogDir%\log_erros_%timestamp%.txt"

:: controle do tempo decorrido
set /a "elapsedTime=0"

:: tempo de espera de 7200 segundos (ou 2 horas) para termino de todos os uploads, a fim de evitar deadlock
set "timeout=7200"  

:: intervalo de espera em cada iteração do loop (em segundos) para verificar o termino dos uploads ativos
set /a "waitInterval=5"  

:: Cria os diretórios se eles não existirem.
if not exist "%flagDir%" mkdir "%flagDir%"
if not exist "%errorLogDir%" mkdir "%errorLogDir%"

:: Limpa o diretório de sinalização antes de iniciar os uploads.
del "%flagDir%" /q

:: Limpa os arquivos temporarios com extensao .error do diretório de erros antes de iniciar os uploads.
dir "%errorLogDir%\*.error" >nul 2>&1 && del "%errorLogDir%\*.error" /q

:: Verifica se a data foi passada como parâmetro.
if "%~1"=="" (
    echo %date% %time% - Especifique a data de modificacao no formato AAAA-MM-DD. >> "%errorFilePath%"
    exit /b 1
)

:: Data especificada no formato AAAA-MM-DD para comparação.
set "dateFilter=%~1"

:: Ajusta a data especificada para o formato AAAAMMDD para compatibilidade com o WMIC.
set "dateFilterStr=!dateFilter:~0,4!!dateFilter:~5,2!!dateFilter:~8,2!"

:: Cria o diretorio para os arquivos de sinalizacao caso nao exista
set "flagDir=%sourceDir%flags"
if not exist "%flagDir%" mkdir "%flagDir%"

:: Configura o número máximo de requisições concorrentes para a AWS CLI.
set /a maxConcurrentRequests=20
aws configure set default.s3.max_concurrent_requests %maxConcurrentRequests%

:: Itera apenas sobre os arquivos no diretório especificado, sem entrar nos subdiretórios.
for %%f in ("%sourceDir%*") do (
    set "fileName=%%~nxf"
    set "filePath=%%~f"
    
    :: Obtem a data de modificação do arquivo usando WMIC e ajusta para o formato AAAAMMDD.
    for /f "tokens=2 delims==" %%m in ('wmic datafile where name^="!filePath:\=\\!" get LastModified /value ^| find "LastModified"') do set "modDate=%%m"
    set "modDate=!modDate:~0,8!"
    
    :: Compara as datas.
    if "!modDate!" geq "!dateFilterStr!" (
		start /B cmd /c upload_arquivo.bat "!filePath!" "!bucket!" "!pathPrefix!" "!fileName!" "%flagDir%" "%errorLogDir%" "%errorFilePath%"
    )
)

:: Loop de monitoramento para verificar a conclusão dos uploads.
:monitor
set /a "activeUploads=0"
for /f %%A in ('dir /b "%flagDir%" 2^>nul ^| find /c /v ""') do set /a "activeUploads=%%A"

if %activeUploads% gtr 0 (
    if %elapsedTime% lss %timeout% (
        timeout /t %waitInterval% >nul
        set /a "elapsedTime+=waitInterval"
        goto monitor
    ) else (
        echo %date% %time% - Timeout de 2 horas atingido. >> "%errorFilePath%"
    )
)

:: Contagem de falhas de upload e consolidacao de logs de erro em arquivo final.
set /a "failedUploads=0"
for /f %%A in ('dir /b "%errorLogDir%\*.error" 2^>nul') do (
	type "%errorLogDir%\%%A" >> "%errorFilePath%"
	set /a failedUploads+=1
)

echo Uploads concluidos. %failedUploads% falhas.

:: Exclui o diretório de sinalização apos os uploads.
rmdir "%flagDir%" /s /q

:: Limpa os arquivos temporarios com extensao .error do diretório de erros apos os uploads.
dir "%errorLogDir%\*.error" >nul 2>&1 && del "%errorLogDir%\*.error" /q

:: Após todas as operações
set /a "exitCode=%failedUploads%"

:: Codigo de saida nao pode ser maior do que 255, mesmo que ocorra mais do que 255 erros de upload
if %failedUploads% gtr 255 set /a "exitCode=255"

:: Usa o exitCode com a contagem de falhas de upload como o código de saída do script
exit /b %failedUploads%

endlocal