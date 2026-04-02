# 🚀 HPC Data Download

[![DOI](https://zenodo.org/badge/1196527929.svg)](https://doi.org/10.5281/zenodo.19339905)

**An HPC-to-Local data transfer pipeline with native cryptographic auditing.**

In bioinformatics and data science, transferring large volumes of data from a High-Performance Computing (HPC) environment to local workstations requires more than a simple copy command. It demands mathematical assurance that not a single byte was corrupted or lost during network transit.

`hpc_data_download` is a smart Bash wrapper designed to scale across any Linux server. It orchestrates remote hash calculation, resilient transfer, and local validation in a single command.

## ✨ Key Features

* 🧠 **Smart Target Resolution:** Automatically detects whether the remote target is an isolated file or an entire directory, dynamically adjusting the hashing and copying strategy.
* 🔐 **Cryptographic Auditing (Reverse):** The source of truth is the server. The script forces the HPC to calculate SHA-256 hashes of the files *before* transfer, and forces the local machine to audit these receipts immediately after the download.
* 🛡️ **Resilient Transfer:** Uses `rsync` to allow resuming interrupted downloads without losing any progress.
* 🍎 **OS-Aware:** Automatically detects if the local machine runs macOS or Linux/WSL, adjusting cryptographic binaries (`shasum` vs `sha256sum`) and injecting power-management protections (like `caffeinate` on Mac to prevent sleep during the download).

## ⚙️ Prerequisites

* Configured SSH access (preferably with multiplexing/RSA keys) to the remote server. See our companion tool: `hpc_ssh_multiplexing`.
* Runs natively on **macOS** (zsh/bash) and **Linux/WSL** terminals.

## 🛠️ Installation

To install and use the tool as a native system command, simply clone the repository and run our automated installation script. 

You can download it anywhere on your machine (like the `Downloads` folder), as the installer will handle the rest. Open your terminal and run the commands below:

```bash
# 1. Clone the repository
git clone [https://github.com/thiagoparentefiocruz/hpc_data_download.git](https://github.com/thiagoparentefiocruz/hpc_data_download.git)

# 2. Enter the cloned directory
cd hpc_data_download

# 3. Run the installer
bash install.sh
```

*(The `install.sh` script will securely copy the executable to `~/.local/bin` and automatically configure your `PATH` if necessary).*

**Cleanup (Optional):**
Since the installer makes a physical copy of the file, you can delete the downloaded folder right after installation to keep your computer organized:

```bash
cd ..
rm -rf hpc_data_download
```

## 📖 Usage

The syntax follows the standard Unix copy pattern: `<Remote_Source> <Local_Destination>`. After installation, the tool is globally available in any terminal.

```bash
hpc_data_download <username@server:/path/to/remote_target> </path/to/local_folder>
```

**Practical Example:**
```bash
hpc_data_download username@hpc.cluster.edu:/home/username/projects/ngs_run1/ ~/MyExperiments/NGSSamples/
```

## 🏗️ Architecture (Under the Hood)

When executed, the pipeline strictly follows 3 phases:

1. **Remote Profiling & Hashing:** Executes an SSH sub-shell on the target server, identifies the nature of the data (file or folder), runs an iterative `find`, and generates a `.txt` manifest file containing the source-based SHA-256 hashes.
2. **Syncing:** Opens an optimized Rsync tunnel. If the connection drops, simply run the exact same command line to resume from the failure point.
3. **Local Audit:** Reads the downloaded manifest on the destination machine and verifies byte-by-byte that the local files perfectly match the server's image.
