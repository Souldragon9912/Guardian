# 🛡️ Guardian Suite

Guardian is a custom-built, interactive terminal dashboard designed for rapid system diagnostics, user auditing, and network troubleshooting in Debain distros. 

Developed as a comprehensive lab project for network security analysis, Guardian wraps complex system checks into a clean, mouse-navigable UI using `fzf`, eliminating the need to memorize long strings of bash commands during critical diagnostic sessions.

## ⚙️ Features

* **G-SEC (Security Audit):** Runs a full system security check. There is a planned CVE check comming soon. Although, that might have its own option.
* **G-PASS (Shadow Audit):** Analyzes local user passwords Against NIST Standards
* **GUI Launcher:** Automatically generates a `.desktop` shortcut and system icon for integration into standard Linux desktop environments (like KDE/GNOME).
* 
-  Anything below this is still in the building phaze and not yet release -
* **G-TOP (Process Monitor):** An interactive, real-time process manager.
* **G-NET (Network/Power Diagnostics):** Scans system logs (`wtmp`, `journalctl`) to detect uncontrolled power losses, hardware disconnects, and network instability.
* **Global Command Integration:** Installs natively to `/usr/local/bin` for system-wide execution.

--

## 📋 Prerequisites

Guardian requires the following packages to run the interactive dashboard:
* `bash` (v4.0+)
* `fzf` (Fuzzy finder for the interactive menu)
* `dialog` (For secondary UI elements)

On Debian/Ubuntu-based systems, install dependencies via:
\`\`\`
sudo apt update && sudo apt install fzf dialog
\`\`\`

## 🚀 Installation

Guardian includes an automated installation script that sets execution permissions, creates a global symlink, and registers the desktop icon. I understand it is annoying to do this manually, I am trying to set it up so it runs automatically. For now, this is the best way because it works best. An uninstall script will be comming soon and packaged with the installer.

1. Clone the repository:

git clone https://github.com/Souldragon9912/Guardian.git

3. Move to the Directory

cd Guardian

6. Make sure install.sh can be executed:

chmod +x install.sh

5. Execute the install script

sudo ./install.sh


## 💻 Usage

Once installed, you can launch the suite from any terminal directory by simply typing:
\`\`\`bash
guardian
\`\`\`
Alternatively, if you are using a desktop environment, search for **Guardian** in your application launcher.
