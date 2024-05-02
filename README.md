## Introdução:

Os 2 scripts *.bat* contidos neste repositório funcionam em conjunto para realizar uploads para um bucket S3, baseando-se na data de modificação dos arquivos. Eles devem estar localizados no mesmo diretório.

##### 1. Navegação até o diretório dos scripts:

•	Navegue, usando o terminal (*cmd*), até o diretório onde os scripts *.bat* estão salvos. Por exemplo:

```
cd C:\path\to\my\source\dir 
```

##### 2. Execução do Script Principal:

•	Execute o script principal fornecendo a data de modificação como parâmetro. O formato da data deve ser *AAAA-MM-DD*. Por exemplo, para executar o script para arquivos modificados a partir de 1º de janeiro de 2021:

```
.\copiar_arquivos_s3.bat 2021-01-01 
```

•	O script irá iterar pelos arquivos no diretório especificado (`sourceDir`), realizar o upload daqueles que foram modificados na data especificada ou depois dela e gerar logs de qualquer falha de upload.



## Pré-requisitos:

##### 1. **Instalação da AWS CLI:**

•	Visite a página oficial da AWS CLI (AWS Command Line Interface) e siga as instruções para a versão mais recente compatível com seu sistema operacional.

•	Após o download, execute o instalador e siga as instruções na tela.

##### 2. **Configuração da AWS CLI:**

•	Após a instalação, abra o terminal (Cmd no Windows) e execute o seguinte comando para configurar suas credenciais de acesso (AccessKey e SecretKey):

```
aws configure
```

•	Durante o processo, será solicitado que você forneça:
•	AWS Access Key ID
•	AWS Secret Access Key
•	Default region name (opcional): pressione [Enter] para continuar
•	Default output format (opcional) pressione [Enter] para continuar
•	Insira suas credenciais de acesso obtidas através do console da AWS.



## Considerações Finais:

•	O script automaticamente cria os diretórios necessários para os arquivos de sinalização e logs de erros, e os limpa antes de iniciar os uploads.

•	Os uploads são realizados de forma assíncrona, com um tempo máximo de espera configurado para 2 horas, a fim de evitar deadlocks. O timeout de espera pelos uploads é ajustável (`timeout=7200` segundos) e pode ser modificado conforme o tamanho dos arquivos e a velocidade de conexão. Ajuste esse valor para evitar deadlocks em ambientes com diferentes capacidades de processamento e velocidade de rede;

•	É importante garantir que a AWS CLI esteja corretamente configurada e que você tenha permissões adequadas para realizar uploads no bucket S3 especificado;

•	O número máximo de requisições concorrentes afeta a performance dos uploads e é configurável (`default.s3.max_concurrent_requests`). Essa configuração afeta como os uploads são processados pelo script. Aumentar o número pode melhorar a velocidade de upload ao permitir múltiplas transferências simultâneas, mas também pode aumentar o uso de recursos da rede e do sistema. O valor padrão é 20, mas você pode ajustá-lo conforme as necessidades específicas do seu ambiente e as capacidades do sistema de onde o script é executado.

•	Execução do Script por uma Aplicação VB.NET: Garanta que a aplicação tenha os privilégios necessários para ler o diretório de origem (`sourceDir`) e manipular os diretórios de sinalização e logs de erros dentro deste caminho. Privilégios adequados são cruciais para a execução sem interrupções.

•	Ao final da execução, o script consolida os logs de erro em um único arquivo (`%errorFilePath%`) e fornece uma contagem de falhas de upload.

•	Um `exitCode` igual a 0 indica uma execução bem-sucedida do script, sem erros de upload detectados. Este padrão segue a convenção comum em sistemas operacionais onde um código de retorno 0 sinaliza sucesso, facilitando a integração com outras ferramentas e scripts que verificam o resultado da execução com base no código de saída.

•	O código de saída (`exitCode`) do script é definido igual ao número de `uploadErrors` (erros de upload), permitindo uma fácil verificação do resultado do processo de upload. Em casos de exceção, como a especificação de uma data inválida, o exitCode será definido como 1 para refletir essa condição, facilitando a identificação de erros de entrada ou configuração.

<u>**Importante**</u>: devido à limitação do sistema, o `exitCode` não pode ser maior que 255. Se o número de `uploadErrors` exceder 255, o `exitCode` será definido para 255, indicando que ocorreram múltiplos erros de upload, mesmo que o número real seja maior.