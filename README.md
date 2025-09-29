# ⚡ Windows Optimization Suite (PowerShell)

A modular, automated optimization framework written in **PowerShell** to streamline, clean, and accelerate Windows systems.  
Each optimization area is segregated into its own module (System, Storage, RAM, Drivers), with a central orchestrator to run them individually or all at once.

---

## ✨ Features

### 🖥️ System Optimization
- Clear temp files, caches, and recycle bin  
- Remove Windows bloatware (AppX packages)  
- Tune or disable heavy background services (e.g., SysMain, WSearch, DiagTrack)  
- Control Windows Update behavior (disable, manual, or default)  

### 💾 Storage Optimization
- Safe SSD retrim or HDD defrag (with fallback to `defrag.exe`)  
- Foreground I/O scheduling bias for active apps  
- Background process throttling to reduce disk thrash  

### 🧠 RAM Optimization
- Prioritize the active foreground process  
- Safe working set trimming with exclusions for critical processes  
- Dampened trimming to avoid CPU spikes or over‑paging  

### 🔧 Driver Management
- OEM‑first driver update workflow  
- Stage `.inf` packages in a local folder and install via `pnputil`  
- Keeps hardware up to date without relying on Windows Update  

### 🛡️ Core Framework
- Snapshot‑first design: restore points + registry exports before changes  
- Before/after metrics (CPU, RAM, Disk Queue, I/O rates)  
- Centralized logging and audit trail for every run  
- Configurable via `config.json`  

---

## 📂 Repository Structure
Optimization/
├── Core/        # Core functions: logging, snapshots, metrics
├── System/      # System cleanup, bloat removal, service tuning 
├── Storage/     # Disk optimization, I/O prioritization 
├── RAM/         # Memory optimization, working set trimming 
├── Drivers/     # OEM driver update workflow 
├── config.json  # Global configuration 
└── run_optimize.ps1  # Orchestrator script

---

## 🚀 Usage

1. Clone the repository:
   ```powershell
   git clone https://github.com/Maigi31/Full-System-Optimization-EXC-Network/
      cd Optimization
.\run_optimize.ps1 -Scope System
.\run_optimize.ps1 -Scope Storage
.\run_optimize.ps1 -Scope RAM
.\run_optimize.ps1 -Scope Drivers
.\run_optimize.ps1 -Scope All
