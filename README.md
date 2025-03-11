# 🚀 Ollama + DeepSeek 7B + Open WebUI (Persistent Memory)

This project sets up a **self-hosted AI assistant** using **Ollama** and **DeepSeek 7B**, with **Open WebUI** as the front-end interface.  
The AI is configured to **remember past conversations** and **runs locally on port 80** for easy access.

---

## **✨ Features**
✅ **Ollama** - Local AI model runtime  
✅ **DeepSeek 7B** - Advanced open-source AI model  
✅ **Persistent Memory** - AI remembers past conversations  
✅ **Open WebUI** - ChatGPT-style user interface  
✅ **Runs on Port 80** - Access via a web browser  
✅ **Automatic Start on Boot**  
✅ **Update & Uninstall Scripts for Easy Management**  

---

# **📥 Step 1: Installation**
### **1️⃣ Clone the Repository**
Run the following commands on your server:
```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
chmod +x install.sh run.sh update.sh stop.sh uninstall.sh
```

### **2️⃣ Run the Installation Script**
```bash
./install.sh
```
This will:
- Install **Ollama**, **DeepSeek 7B**, and **Open WebUI**
- Check and install **missing dependencies** (Docker, Python, Nginx, etc.)
- Configure **AI memory storage** in `/home/$(whoami)/data/`
- Start **all services automatically**  

---

# **🌐 Step 2: How to Access the AI System**
### **1️⃣ Access the Web App**
Once installed, open your browser and visit:

👉 **http://your-server-ip**  
or  
👉 **http://localhost** *(if running locally)*  

---

# **🛠️ Step 3: Managing the AI System**
### **1️⃣ Start & Ensure AI is Running**
If the AI system is not running, start it with:
```bash
./run.sh
```

### **2️⃣ Stop the AI Assistant**
To **stop all AI services**, run:
```bash
./stop.sh
```

### **3️⃣ Restart the AI Assistant**
To restart both **Ollama and Open WebUI**, run:
```bash
sudo systemctl restart ollama
cd /home/$(whoami)/open-webui
sudo docker-compose restart
```

---

# **🔄 Step 4: Updating the AI Assistant**
To **update Ollama, DeepSeek 7B, and Open WebUI** while preserving AI memory, run:
```bash
./update.sh
```

This will:
- **Update system libraries**  
- **Update Ollama & DeepSeek 7B** (without deleting AI memory)  
- **Pull the latest Open WebUI updates**  

---

# **🗑️ Step 5: Uninstalling the AI Assistant**
To **completely remove** the AI system, run:
```bash
./uninstall.sh
```

This will:
✅ **Stop and remove all AI services**  
✅ **Delete Ollama & DeepSeek 7B**  
✅ **Remove AI memory storage (`/home/$(whoami)/data/`)**  
✅ **Uninstall all dependencies**  

---

🚀 **Enjoy your personal AI assistant!** 🎉
