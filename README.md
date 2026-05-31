# 🛡️ The Guardian Suite overview:

Guardian is a simple and easy-to-use tool that combines multiple different modules to perform different tasks. Each of the tools has its own priority and use cases, some being root-only and others being general use. Every tool is in one of two categories:

Root Only  
These tools consist of G-SEC, G-UFW, and G-Hardware. These tools are root-only because they make system-level changes or affect security or go in-depth further in the system that requires root permissions.

General tools   
G-Vault, G-pass, and G-ventoy. The general tools are available to all users on the system. Each one of these tools performs different tasks ranging from securely storing files to auditing the users' passwords to ensure they meet NIST guidelines. G-Ventoy is the only one that is slightly different because it is simply used to install or update pre-existing Ventoy drives if the user owns one.


## 📋 Dependencies

Guardian requires the following packages to run the interactive dashboard:
* `bash` (v4.0+)
* `fzf` (Fuzzy finder for the interactive menu)
* `dialog` (For secondary UI elements)

## Installation
Guardian includes an automated installation script that sets execution permissions, creates a global symlink, and registers the desktop icon. I understand it is annoying to do this manually, I am trying to set it up so it runs automatically. For now, this is the best way because it works best. An uninstall script will be comming soon and packaged with everything. during testing, it kinda nuked my downloads dir. so, it will be a bit before that's released.

1. Clone the repository:

git clone https://github.com/Souldragon9912/Guardian.git

3. Move to the Directory

cd Guardian

6. Make sure install.sh can be executed:

chmod +x install.sh

5. Execute the install script

sudo ./install.sh

## one-liner (expiremental)
This is a new one-liner to get the install going. if its not working, please let us know.

##
git clone https://github.com/Souldragon9912/Guardian.git && cd Guardian && sudo ./G-Manager.sh
## 

## Ethical & Authorized Use Statement

The Guardian Suite is to be run locally as intended with some tools requiring admin privileges, while others can be used by the general user. Each of the tools have their own priority and use case and some are strictly limited to root access or administrative users for the security related tools. **Data will not be collected**. The authors of Guardian will not see any of your data. Everything will be run locally on your system. This tool is used for security and system analysis only. It is never transmitted to the author or any external parties.. Ultimately, the responsibility for maintaining confidentiality lies with the user should information be disclosed to anyone outside of the system owner, administrator, or executive management

## Authorization & Rules of Engagement

This tool is designed to assist in identifying misconfigurations and vulnerabilities within a controlled environment. By executing this script, the user confirms they have:

1. Explicit Ownership: The user is the owner of the system being audited.  
2. Written Permission: The user has received explicit, written authorization from the system owner to conduct a security assessment.  
3. Backup Verification: A current, verified backup of the target system exists prior to the commencement of the audit.

# Risk Prioritization

While using Guardian, there are many risks that are associated and found, so the risk prioritization will be labeled in red for severe risk, yellow for medium risks, and green for non-essential risks that are found. Many of them can include risks such as:

* Remote administrative access through SSH  
* Potentially users who have a UID of zero, in other words, users who have root access that potentially shouldn't

For example, once the CVE tool is produced for this, it will scan your system for any potential CVEs. For example, there is a zero-day attack known as “Dirty Frag” that gives root access on all major distros right now. If your system is found to have that specific CVE, it will highlight that CVE in red and give a brief description of it, and encourage the user to search and find remediation through the provided links that will be there.   
Guardian focuses on identifying configuration based risks through analysis and inspection, rather than actively exploiting the system. Plans to implement future CVE awareness features to help out with known vulnerabilities and remediation steps is in the works as well.

| Vulnerability | Severity | Likelihood | Impact | Risk Level | Justification |
| ----- | ----- | ----- | ----- | ----- | ----- |
| Root Access through SSH | Medium | High | High | High | The allowance of root access to SSH is a significant risk factor. With SSH providing remote administrative control, misconfigurations can lead to compromisations, and lead into full system takeover. This is why the combination of high likelihood and high impact results in an overall high risk. |

## **Engagement Overview**

In the event that a vulnerability is found, whether it be through G-CVE or G-SEC, it will be notified to the user through a given API and logged. At the start of Guardian it will request that information to be able to notify the user in case certain checks take longer than expected, such as a virus scan, because those can take up to two and a half to four hours.

If there's anything found, the specific CVE that is detected through G-CVE will be highlighted in red and a brief description will be given along with a link to the database to be able to search and find possible remediation steps that are provided by Canonical.

### Remediation Steps

With the many CVEs that can be discovered through scanning, Guardian cannot and will not give any remediation steps because at the time of discovery as there may not be any known remediation steps. It will be advised to the end user to search up their specific CVE that was found through the canonical security database to find whether or not they have listed any remediation steps. If they have listed any remediation steps, it is the sole discretion of the user to determine the next steps of action. This tool only provides the ability to search. It does not provide any advice as to what to do in the event of a discovered vulnerability.

### Database Dependency

Guardian relies on external, third-party databases (such as Canonical’s Ubuntu Security Notices) for vulnerability information. Guardian is not responsible for the accuracy, uptime, or completeness of these external resources.

### False Positives

Security scanning may occasionally result in 'False Positives.' Users are encouraged to verify findings manually before taking drastic remediation actions, such as deleting critical system files or disabling services.

# **Engagement Overview & Operational Framework**

In the event that a vulnerability or system anomaly is identified via the G-CVE or G-SEC, the event is immediately recorded to the local persistent logs and dispatched asynchronously to the user interface via the integration API, textSMS, or NTFY

Upon execution, the Guardian Security Suite initializes an outbound data request to establish tracking states. This design guarantees consistent telemetry reporting during long-running security tasks—such as full filesystem or cryptographic signature audits—which typically require an operational window of 2.5 to 4 hours depending on system constraints.

## Vulnerability Flagging & Database Integration

When a verified risk is surfaced by the G-CVE module:

* The identified Common Vulnerabilities and Exposures (CVE) identifier is highlighted in red within the continuous monitoring terminal interface.  
* A list detailing the technical threat vectors is displayed alongside the flag.  
* A direct hyperlink is appended to the log entry, mapping the vector directly to the vendor definitions for inspection.

## Remediation Protocols & Liability Scope

Due to the volatile and rapidly shifting nature of newly published exploits, the Guardian Security Suite operates strictly as an auditing and discovery tool. 

Guardian does not execute patches, configuration modifications, or provide operational fix scripts at the time of discovery, as validated remediation pathways may not yet be established by the industry.

#  Guardian Vault

The G-Vault module is a terminal-driven cryptographic storage manager built for maximum stealth, persistent metadata integrity, and anti-forensic asset handling. By utilizing a proprietary container architecture and volatile memory execution, G-Vault guarantees that secured data remains invisible and completely irretrievable post-purge. This module was Ai assisted to ensure that all functions worked properly. 

## Proprietary Header Injection & Asset Architecture

* Metadata Persistence: G-Vault bypasses standard extended attributes (xattr) to prevent data loss during cross-platform transfers. It dynamically manipulates the binary stream to inject a custom signature (GUARDIAN\_META\_V1) directly into the payload.  
* Cryptographic Masking: Target assets are secured via AES-256 symmetric encryption and designated with the proprietary .grdn (Guardian) extension. This containerization fully masks the asset's underlying MIME-type and structural DNA from forensic indexing.

## Zero-Footprint Inspection & Sanitization

* Volatile Memory Execution: When a user inspects a .grdn file without permanent extraction, G-Vault establishes a secure transient state within the node's volatile memory (/dev/shm). The asset is decrypted strictly into this RAM disk. Upon viewer exiting the file, an immediate purge of the memory sector is executed, ensuring zero byte leakage to physical solid-state or hard disk drives.  
* Post-Encryption Shredding: Following successful cryptographic packaging, G-Vault initiates an optional sector-level sanitization protocol (shred \-u), repeatedly overwriting the original unencrypted source file to neutralize potential data recovery vectors.


**End-User Agreement & Liability Waiver:** The Guardian Security Suite and G-Vault are provided "as is" without warranty of any kind, express or implied. By deploying or utilizing this vault, the user accepts 100% of the risk associated with its use, including the absolute risk of permanent data loss.


* **G-SEC (Security Audit):** Runs a full system security check. There is a planned CVE check comming soon. Although, that might have its own option.
* **G-PASS (Shadow Audit):** Analyzes local user passwords Against NIST Standards
* **GUI Launcher:** Automatically generates a `.desktop` shortcut and system icon for integration into standard Linux desktop environments (like KDE/GNOME).
* 
-  Anything below this is still in the building phaze and not yet release -
* **G-TOP (Process Monitor):** An interactive, real-time process manager.
* **G-NET (Network/Power Diagnostics):** Scans system logs (`wtmp`, `journalctl`) to detect uncontrolled power losses, hardware disconnects, and network instability.
* **Global Command Integration:** Installs natively to `/usr/local/bin` for system-wide execution.


Once installed you should have the application show up in your applications menu or the actual command should be working and you'll just be able to type in guardian and launch it in the terminal 
