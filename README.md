# 🚀 Rieux Data Download

**Um pipeline de transferência de dados HPC-para-Local com auditoria criptográfica nativa.**

Em bioinformática e ciência de dados, transferir grandes volumes de informação de um ambiente de Alta Performance (HPC) para estações de trabalho locais exige mais do que um simples comando de cópia. Exige a garantia matemática de que nenhum byte foi corrompido ou perdido durante o trânsito de rede.

O `rieux_data_download` é um wrapper inteligente em Bash desenhado para o cluster Rieux (Fiocruz), mas escalável para qualquer servidor Linux. Ele orquestra o cálculo de hashes remotamente, a transferência resiliente e a validação local em um único comando.

## ✨ Principais Funcionalidades

* 🧠 **Smart Target Resolution:** O script detecta automaticamente se o alvo remoto é um arquivo isolado ou um diretório inteiro, ajustando a estratégia de hash e cópia dinamicamente.
* 🔐 **Auditoria Criptográfica (Invertida):** A fonte da verdade é o servidor. O script obriga o HPC a calcular as hashes SHA-256 dos arquivos *antes* da transferência, e força a máquina local a auditar esses recibos logo após o download.
* 🛡️ **Transferência Resiliente:** Utiliza `rsync` para permitir a retomada de downloads interrompidos sem perda de progresso.
* 🍎 **OS-Aware:** Detecta automaticamente se a máquina local roda macOS ou Linux, ajustando os binários criptográficos (`shasum` vs `sha256sum`) e injetando proteções de energia (como o `caffeinate` no Mac para evitar suspensão durante o download).

## ⚙️ Pré-requisitos

* Acesso SSH configurado (preferencialmente com multiplexação/chaves RSA) para o servidor remoto. Ver função: rieux_ssh_multiplexing
* Funciona nativamente em terminais **macOS** (zsh/bash) e **Linux/WSL**.

## 🛠️ Instalação

1. Clone o repositório para o seu cofre de scripts locais:
   ```bash
   git clone [https://github.com/thiagoparentefiocruz/rieux_data_download.git](https://github.com/thiagoparentefiocruz/rieux_data_download.git) ~/Documents/repositorios_github/rieux_data_download
   ```

2. Adicione o carregamento do script ao seu arquivo de configuração do terminal (~/.zshrc no Mac ou ~/.bashrc no Linux):
   ```bash
   echo "source ~/Documents/repositorios_github/rieux_data_download/rieux_data_download.sh" >> ~/.zshrc
   source ~/.zshrc
   ```

3. 📖 Como Usar
A sintaxe segue o padrão de cópia do Unix: <Origem_Remota> <Destino_Local>.
   ```bash
   rieux_data_download <usuario@servidor:/caminho/remoto> </caminho/pasta_local>
   ```

4. 🏗️ Arquitetura (Under the Hood)
Quando executado, o pipeline segue estritamente 3 fases:

Remote Profiling & Hashing: Executa um sub-shell SSH no servidor alvo, identifica a natureza do dado, executa um find iterativo e gera um arquivo de manifesto .txt contendo as hashes SHA-256 baseadas na origem.

Syncing: Abre um túnel Rsync otimizado. Se a conexão cair, basta rodar a exata mesma linha de comando para retomar do ponto de falha.

Local Audit: Lê o manifesto baixado na máquina de destino e verifica byte a byte se os arquivos locais conferem perfeitamente com a imagem do servidor.
