@echo off
setlocal
set "filePath=%~1"
set "bucket=%~2"
set "pathPrefix=%~3"
set "fileName=%~4"
set "flagDir=%~5"
set "errorLogDir=%~6"
set "errorFilePath=%~7"

:: Cria o arquivo de sinalização
echo > "%flagDir%\%fileName%.flag"

:: Executa o comando AWS CLI
aws s3 cp "%filePath%" "s3://%bucket%/%pathPrefix%/%fileName%" >nul 2>&1

:: Verifica se ocorreu um erro.
if not %errorlevel%==0 (
	echo %date% %time% - Erro ao copiar: %fileName% >> "%errorLogDir%\%fileName%.error"
)

:: Deleta o arquivo de sinalização indicando a conclusão.
del "%flagDir%\%fileName%.flag"