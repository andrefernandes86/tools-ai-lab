# 🚀 AI Assistant - Ollama + DeepSeek 7B + Open WebUI

This project provides a fully functional AI assistant powered by **Ollama**, **DeepSeek 7B**, and **Open WebUI**. It includes automatic installation, updating, and system reboot persistence.

---

## **📌 Features**
✅ **Ollama** – AI model execution engine  
✅ **DeepSeek 7B** – Language model with memory persistence  
✅ **Open WebUI** – Web-based UI for interacting with the AI  
✅ **Automatic startup on reboot**  
✅ **Easy install, update, and stop scripts**

---

## **📌 Installation**
### **Step 1: Clone the Repository**
```bash
git clone https://github.com/andrefernandes86/tools-ai-lab.git
cd tools-ai-lab
```

### **Step 2: Make Scripts Executable**
```bash
chmod +x install.sh run.sh update.sh stop.sh
```

### **Step 3: Run the Installation**
```bash
./install.sh
```
- This installs **all dependencies** (Docker, Python, Ollama, DeepSeek 7B, and Open WebUI).
- The AI **remembers previous interactions**.
- It **configures Open WebUI on port 80**.

---

## **📌 Access the AI Assistant**
After installation, you can access Open WebUI at:

🔗 **http://your-server-ip:3000**

---

## **📌 Running the AI Assistant**
By default, the system runs **automatically on every reboot**.

### **Manual Start**
To manually start the AI assistant, run:
```bash
./run.sh
```

### **Stopping the AI**
To stop the AI and all running services:
```bash
./stop.sh
```

---

## **📌 Updating the System**
To update core components without losing AI memory:
```bash
./update.sh
```

---

## **📌 Automatic Startup on Reboot**
The system is configured to **automatically restart on every boot** using `crontab`.

To manually check or re-enable the startup script:
```bash
sudo crontab -e
```
Ensure this line is added:
```bash
@reboot /home/$(whoami)/tools-ai-lab/run.sh >> /home/$(whoami)/tools-ai-lab/logs/run.log 2>&1
```

---

## **📌 Uninstalling Everything**
To completely remove the AI assistant:
```bash
./uninstall.sh
```
This will:
- Stop all services
- Remove all installed components
- Delete AI memory and logs

---
