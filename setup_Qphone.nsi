; ##################################################################
; #  Script de Distribuição Global para MicroSIP com NSIS          #
; #  Compilado em Linux para Windows                               #
; #  Versão Final com Cópia de Pasta e Configuração .ini           #
; ##################################################################

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"

; --- 1. Propriedades e Branding ---
Name "Qphone Softphone"
OutFile "setup_Qphone.exe"
InstallDir "$PROGRAMFILES\Qphone"
RequestExecutionLevel admin

; --- 2. Recursos Visuais (Ícone e Imagens) ---
!define MUI_ICON "assets\setup_icon.ico"
!define MUI_UNICON "assets\setup_icon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "assets\header_image.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "assets\welcome_finish.bmp" ; Opcional

; --- 3. Variáveis Globais para os dados do usuário ---
Var /GLOBAL VAR_RAMAL
Var /GLOBAL VAR_SENHA
Var /GLOBAL VAR_DOMINIO
Var /GLOBAL VAR_AUTOANSWER 

; --- 4. Configuração da Interface (Páginas) ---
!insertmacro MUI_PAGE_WELCOME

; --- Página Customizada para Inserir Dados ---
Page custom PageConfigShow PageConfigLeave ""

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; --- 5. Idiomas ---
!insertmacro MUI_LANGUAGE "PortugueseBR"

; --- 6. Funções das Páginas Customizadas ---

; Função executada ao entrar na página de configuração
Function PageConfigShow
    ; Título da página
    !insertmacro MUI_HEADER_TEXT "  Configuração da Conta" "Por favor, insira os dados da sua conta Qphone."

    ; Cria um formulário temporário para a página
    InstallOptions::dialog "$PLUGINSDIR\config.ini"
    Pop $0 ; Descarta o valor de retorno
FunctionEnd

; Função executada ao sair da página (clicar em Próximo)
Function PageConfigLeave
    ; Lê os valores dos campos e os salva nas variáveis
    ReadINIStr $VAR_RAMAL "$PLUGINSDIR\config.ini" "Field 3" "State"
    ReadINIStr $VAR_SENHA "$PLUGINSDIR\config.ini" "Field 5" "State"
    ReadINIStr $VAR_DOMINIO "$PLUGINSDIR\config.ini" "Field 7" "State"
    ReadINIStr $VAR_AUTOANSWER "$PLUGINSDIR\config.ini" "Field 8" "State"


    ; Validação: Verifica se os campos não estão vazios
    ${If} $VAR_RAMAL == ""
    ${OrIf} $VAR_SENHA == ""
    ${OrIf} $VAR_DOMINIO == ""
        MessageBox MB_OK|MB_ICONEXCLAMATION "O Ramal, a Senha e o Servidor são campos obrigatórios."
        Abort ; Impede o usuário de avançar
    ${EndIf}
FunctionEnd


; --- 7. Função de Inicialização do Instalador ---
Function .onInit
    ; Extrai o arquivo que define a aparência da página customizada
    InitPluginsDir
    File /oname=$PLUGINSDIR\config.ini "config_page.ini"
FunctionEnd

; ##################################################################
; #  Seção de Instalação Principal                                 #
; ##################################################################
Section "Qphone Core" SEC_CORE

    !define DOWNLOAD_URL_ZIP "https://qosit.cloud/downloads/Qphone/Qphone.zip"
    !define DOWNLOAD_URL_INI "https://qosit.cloud/downloads/Qphone/microsip_template.ini"

    SetOutPath "$INSTDIR"

    ; --- Passo 1: Download ---
    InetC::get /POPUP "Baixando Qphone..." /CAPTION "Progresso do Download" "${DOWNLOAD_URL_ZIP}" "$INSTDIR\Qphone.zip"
    Pop $0
    ${If} $0 != "OK"
        MessageBox MB_OK|MB_ICONSTOP "O download falhou: $0$\n\nA instalação não pode continuar."
        Quit
    ${EndIf}

    ; --- Passo 2: Extração ---
    DetailPrint "Extraindo arquivos..."
    nsisunz::UnzipToLog "$INSTDIR\Qphone.zip" "$INSTDIR"
    Pop $0
    ${If} $0 != "success"
        MessageBox MB_OK|MB_ICONSTOP "Falha ao extrair os arquivos: $0"
        Quit
    ${EndIf}
    ; Delete "$INSTDIR\Qphone.zip"

    ; --- Passo 3: Baixar INI ---
    DetailPrint "Baixando modelo de configuração..."
    InetC::get "${DOWNLOAD_URL_INI}" "$INSTDIR\microsip.ini"
    Pop $0
    ${If} $0 != "OK"
        MessageBox MB_OK|MB_ICONSTOP "O download do arquivo de configuração falhou: $0"
        Quit
    ${EndIf}

    ; --- Passo 4: Adicionar os dados da conta ao arquivo .ini ---
    DetailPrint "Configurando a conta de usuário..."
    WriteINIStr "$INSTDIR\microsip.ini" "Account1" "accountName"    "$VAR_RAMAL"
    WriteINIStr "$INSTDIR\microsip.ini" "Account1" "sipServer"      "$VAR_DOMINIO"
    WriteINIStr "$INSTDIR\microsip.ini" "Account1" "userName"       "$VAR_RAMAL"
    WriteINIStr "$INSTDIR\microsip.ini" "Account1" "domain"         "$VAR_DOMINIO"
    WriteINIStr "$INSTDIR\microsip.ini" "Account1" "login"          "$VAR_RAMAL"
    WriteINIStr "$INSTDIR\microsip.ini" "Account1" "password"       "$VAR_SENHA"
    WriteINIStr "$INSTDIR\microsip.ini" "Account1" "enabled"        "1"
    WriteINIStr "$INSTDIR\microsip.ini" "Settings" "autoAnswer"     "$VAR_AUTOANSWER"
    WriteINIStr "$INSTDIR\microsip.ini" "Settings" "AA"             "$VAR_AUTOANSWER"

    ; --- Passo 5: Criar o Desinstalador ---
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; Cria atalhos
    CreateDirectory "$SMPROGRAMS\Qphone"
    CreateShortCut "$SMPROGRAMS\Qphone\Qphone Softphone.lnk" "$INSTDIR\microsip.exe"
    CreateShortCut "$DESKTOP\Qphone Softphone.lnk" "$INSTDIR\microsip.exe"

SectionEnd


; ##################################################################
; #  Seção do Desinstalador                                        #
; ##################################################################
Section "Uninstall"

    ; Deleta os arquivos e a pasta principal
    Delete "$INSTDIR\*.*"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir /r "$INSTDIR"

    ; Deleta os atalhos
    Delete "$SMPROGRAMS\Qphone\Qphone Softphone.lnk"
    RMDir "$SMPROGRAMS\Qphone"
    Delete "$DESKTOP\Qphone Softphone.lnk"

SectionEnd


; ##################################################################
; #  Finalização: Assinatura Digital (Versão para Linux)           #
; ##################################################################

!finalize 'osslsigncode sign -pkcs12 "Qphone_installer_cert.pfx" -pass "40637066" -ts "http://timestamp.digicert.com" -in "$%TEMP%\installer.exe" -out "$%TEMP%\installer-signed.exe" && mv "$%TEMP%\installer-signed.exe" "$%TEMP%\installer.exe"'