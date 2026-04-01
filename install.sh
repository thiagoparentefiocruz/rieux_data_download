#!/bin/bash

# Define o diretório de destino padrão (Boa prática)
DEST_DIR="$HOME/.local/bin"

# Pega o nome deste próprio script para não tentar instalá-lo
INSTALLER_NAME=$(basename "$0")

echo "🔍 Procurando programas para instalar no diretório atual..."

# Encontra arquivos executáveis na pasta atual (ignora pastas, arquivos ocultos e o próprio instalador)
EXECUTABLES=$(find . -maxdepth 1 -type f -executable ! -name "$INSTALLER_NAME" ! -name ".*")

if [ -z "$EXECUTABLES" ]; then
    echo "⚠️  Nenhum arquivo executável encontrado."
    echo "Dica: Dê permissão de execução aos seus scripts (ex: chmod +x script.sh) antes de rodar o install.sh."
    exit 1
fi

# Cria o diretório de destino caso ele não exista
mkdir -p "$DEST_DIR"

# Loop de instalação
for exec_file in $EXECUTABLES; do
    filename=$(basename "$exec_file")
    command_name="${filename%.*}" # Remove a extensão
    target_path="$DEST_DIR/$command_name"

    echo "➡️  Instalando '$filename' como o comando '$command_name'..."
    cp -f "$exec_file" "$target_path"
    chmod +x "$target_path"
done

echo "✅ Arquivos copiados com sucesso!"

# ==========================================
# CONFIGURAÇÃO AUTOMÁTICA DO PATH
# ==========================================

# Verifica se o DEST_DIR já está na variável PATH
if [[ ":$PATH:" != *":$DEST_DIR:"* ]]; then
    echo "⚙️  Configurando o PATH..."
    
    # Detecta qual arquivo de configuração de shell alterar
    SHELL_RC=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    # Se encontrou um shell conhecido, adiciona a linha
    if [ -n "$SHELL_RC" ]; then
        echo "" >> "$SHELL_RC"
        echo "# Adicionado pelo instalador" >> "$SHELL_RC"
        echo "export PATH=\"$DEST_DIR:\$PATH\"" >> "$SHELL_RC"
        
        echo "⚠️  O diretório $DEST_DIR foi adicionado ao seu $SHELL_RC."
        echo "💡 IMPORTANTE: Para usar os comandos agora, reinicie o terminal ou rode:"
        echo "    source $SHELL_RC"
    else
        echo "⚠️  Não foi possível detectar seu Shell automaticamente (não é bash nem zsh)."
        echo "💡 Por favor, adicione manualmente a seguinte linha ao arquivo de configuração do seu shell:"
        echo "    export PATH=\"$DEST_DIR:\$PATH\""
    fi
else
    echo "👍 O diretório $DEST_DIR já está no seu PATH."
    echo "🎉 Tudo pronto! Você já pode usar os comandos instalados."
fi

# Mensagem final caso o usuário queira limpar a sujeira
echo "🧹 Você já pode apagar esta pasta clonada do repositório, se desejar."
