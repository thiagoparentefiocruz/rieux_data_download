# 🚀 Rieux Data Download

[![DOI](https://zenodo.org/badge/1196527929.svg)](https://doi.org/10.5281/zenodo.19339905)

**Um pipeline de transferência de dados HPC-para-Local com auditoria criptográfica nativa.**

Em bioinformática e ciência de dados, transferir grandes volumes de informação de um ambiente de Alta Performance (HPC) para estações de trabalho locais exige mais do que um simples comando de cópia. Exige a garantia matemática de que nenhum byte foi corrompido ou perdido durante o trânsito de rede.

O `rieux_data_download` é um wrapper inteligente em Bash desenhado para o cluster Rieux (Fiocruz), mas escalável para qualquer servidor Linux. Ele orquestra o cálculo de hashes remotamente, a transferência resiliente e a validação local em um único comando.

## ✨ Principais Funcionalidades

* 🧠 **Smart Target Resolution:** O script detecta automaticamente se o alvo remoto é um arquivo isolado ou um diretório inteiro, ajustando a estratégia de hash e cópia dinamicamente.
* 🔐 **Auditoria Criptográfica (Invertida):** A fonte da verdade é o servidor. O script obriga o HPC a calcular as hashes SHA-256 dos arquivos *antes* da transferência, e força a máquina local a auditar esses recibos logo após o download.
* 🛡️ **Transferência Resiliente:** Utiliza `rsync` para permitir a retomada de downloads interrompidos sem perda de progresso.
* 🍎 **OS-Aware:** Detecta automaticamente se a máquina local roda macOS ou Linux, ajustando os binários criptográficos (`shasum` vs `sha256sum`) e injetando proteções de energia (como o `caffeinate` no Mac para evitar suspensão durante o download).

## ⚙️ Pré-requisitos

* Acesso SSH configurado (preferencialmente com multiplexação/chaves RSA) para o servidor remoto. Ver ferramenta complementar: `rieux_ssh_multiplexing`.
* Funciona nativamente em terminais **macOS** (zsh/bash) e **Linux/WSL**.

## 🛠️ Instalação

Para instalar e usar a ferramenta como um comando nativo do seu sistema, basta clonar o repositório e rodar o nosso script de instalação automatizada. 

Você pode baixar em qualquer diretório da sua máquina (como a pasta `Downloads`), pois o instalador cuidará de tudo. Abra seu terminal e rode os comandos abaixo:

```bash
# 1. Clone o repositório
git clone [https://github.com/thiagoparentefiocruz/rieux_data_download.git](https://github.com/thiagoparentefiocruz/rieux_data_download.git)

# 2. Entre na pasta clonada
cd rieux_data_download

# 3. Execute o instalador
bash install.sh
```

*(O script `install.sh` copiará o executável de forma segura para `~/.local/bin` e configurará automaticamente o seu `PATH`, caso seja necessário).*

**Limpeza (Opcional):**
Como o instalador faz uma cópia real do arquivo, logo após a instalação você pode apagar a pasta que acabou de baixar para manter seu computador organizado:

```bash
cd ..
rm -rf rieux_data_download
```

## 📖 Como Usar

A sintaxe segue o padrão de cópia do Unix: `<Origem_Remota> <Destino_Local>`. Após a instalação, a ferramenta estará disponível globalmente em qualquer terminal.

```bash
rieux_data_download <usuario@servidor:/caminho/remoto> <caminho/pasta_local>
```

**Exemplo prático:**
```bash
rieux_data_download tparente@rieux.fiocruz.br:/home/tparente/projetos/ngs_run1/ ~/MeusExperimentos/AmostrasNGS/
```

## 🏗️ Arquitetura (Under the Hood)

Quando executado, o pipeline segue estritamente 3 fases:

1. **Remote Profiling & Hashing:** Executa um sub-shell SSH no servidor alvo, identifica a natureza do dado, executa um `find` iterativo e gera um arquivo de manifesto `.txt` contendo as hashes SHA-256 baseadas na origem.
2. **Syncing:** Abre um túnel Rsync otimizado. Se a conexão cair, basta rodar a exata mesma linha de comando para retomar do ponto de falha.
3. **Local Audit:** Lê o manifesto baixado na máquina de destino e verifica byte a byte se os arquivos locais conferem perfeitamente com a imagem do servidor.
