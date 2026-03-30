#!/bin/bash

rieux_data_download() {
    if [ "$#" -ne 2 ]; then
        echo "Uso: rieux_data_download <usuario@rieux:/caminho/remoto_arquivo_ou_pasta> </caminho/pasta_local>"
        return 1
    fi

    local REMOTE_SRC="$1"
    local LOCAL_DEST="$2"
    
    local REMOTE_HOST="${REMOTE_SRC%%:*}"
    local REMOTE_DIR="${REMOTE_SRC#*:}"

    echo "🚀 Iniciando pipeline inteligente de download do Rieux..."

    local OS_TYPE=$(uname -s)
    local CMD_HASH_CHECK=()
    local CMD_RSYNC=()

    case "$OS_TYPE" in
        Darwin*)
            echo "🍎 Sistema detectado: macOS. Configurando caffeinate e shasum..."
            CMD_HASH_CHECK=(shasum -a 256 -c)
            CMD_RSYNC=(caffeinate -i rsync -avP)
            ;;
        Linux*)
            echo "🐧 Sistema detectado: Linux/WSL. Configurando sha256sum..."
            CMD_HASH_CHECK=(sha256sum -c)
            CMD_RSYNC=(rsync -avP)
            ;;
        *)
            echo "❌ Sistema Operacional '$OS_TYPE' não suportado."
            return 1
            ;;
    esac

    local ORIGINAL_DIR=$(pwd)
    
    # Garante que a pasta de destino local exista
    mkdir -p "$LOCAL_DEST"

    echo "---------------------------------------------------"
    echo "Analisando o alvo no Rieux e calculando hashes em tempo real..."
    
    # Pergunta ao servidor se é diretório ou arquivo
    local REMOTE_IS_DIR=$(ssh "$REMOTE_HOST" "[ -d '$REMOTE_DIR' ] && echo 'YES' || echo 'NO'")
    local RSYNC_SRC=""

    if [ "$REMOTE_IS_DIR" = "YES" ]; then
        # É uma pasta: calcula a hash do conteúdo e força a barra no rsync
        ssh "$REMOTE_HOST" "cd '$REMOTE_DIR' && find . -type f ! -path '*/.*' -exec sha256sum {} +" > "$LOCAL_DEST/checksums_remote.txt"
        RSYNC_SRC="${REMOTE_SRC%/}/"
    else
        # É um arquivo solto: calcula a hash apenas dele
        ssh "$REMOTE_HOST" "cd \"\$(dirname '$REMOTE_DIR')\" && sha256sum \"\$(basename '$REMOTE_DIR')\"" > "$LOCAL_DEST/checksums_remote.txt"
        RSYNC_SRC="${REMOTE_SRC}"
    fi

    # Verifica se o arquivo de checksum foi salvo e não está vazio (caso o alvo não exista no servidor)
    if [ ! -s "$LOCAL_DEST/checksums_remote.txt" ]; then
        echo "❌ Erro: O arquivo ou pasta não foi encontrado no Rieux ou está vazio."
        rm -f "$LOCAL_DEST/checksums_remote.txt"
        return 1
    fi
    echo "✅ Checksums remotos mapeados e salvos no seu Mac."

    echo "---------------------------------------------------"
    echo "Iniciando transferência segura (rsync)..."

    "${CMD_RSYNC[@]}" "$RSYNC_SRC" "$LOCAL_DEST/"

    if [ $? -ne 0 ]; then
        echo "❌ Erro ou interrupção na transferência."
        echo "Basta rodar o comando novamente para retomar de onde parou."
        return 1
    fi
    echo "✅ Download concluído."

    echo "---------------------------------------------------"
    echo "Verificando a integridade dos dados locais..."
    
    cd "$LOCAL_DEST" || return 1
    
    # O Mac lê o arquivo de texto gerado e confere se a transferência foi perfeita
    "${CMD_HASH_CHECK[@]}" checksums_remote.txt

    if [ $? -eq 0 ]; then
        echo "---------------------------------------------------"
        echo "🎉 SUCESSO! Transferência validada criptograficamente."
    else
        echo "---------------------------------------------------"
        echo "⚠️ AVISO: A verificação falhou para um ou mais arquivos. Cheque o log acima."
    fi

    cd "$ORIGINAL_DIR"
}

export -f rieux_data_download
