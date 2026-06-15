# Guardian overview:

Guardian is a simple and easy-to-use tool that combines multiple different modules to perform different tasks. Each of the tools has its own priority and use cases, some being root-only and others being general use. Every tool is in one of two categories:

Root Only  
These tools consist of G-SEC, G-UFW, and G-Hardware. These tools are root-only because they make system-level changes or affect security or go in-depth further in the system that requires root permissions.

General tools   
G-Vault, G-pass, and G-ventoy. The general tools are available to all users on the system. Each one of these tools performs different tasks ranging from securely storing files to auditing the users' passwords to ensure they meet NIST guidelines. G-Ventoy is the only one that is slightly different because it is simply used to install or update pre-existing Ventoy drives if the user owns one.

# Installation
Guardian has a simple way to install. There is the manual way or the one-liner.


## One-Liner
git clone https://github.com/Souldragon9912/Guardian.git && cd Guardian/scripts && chmod +x G-Manager.sh && ./G-Manager.sh

## Manual Installation
If you prefer to review the repository before deploying the suite, you can execute the setup process step-by-step:

1. Clone the repository to your local machine:
2. git clone https://github.com/Souldragon9912/Guardian.git
3. cd Guardian
4. chmod +x G-Manager.sh
5. bash G-Manager or ./G-Manager.sh


Engagement Overview  
In the event that a vulnerability is found, whether it be through G-CVE or G-SEC, it will be logged and a push notification will be sent to the desktop.

If there's anything found, the specific CVE that is detected through G-CVE will be highlighted in red and a brief description will be given along with a link to the database to be able to search and find possible remediation steps that are provided by Canonical.

### Remediation Steps

With the many CVEs that can be discovered through scanning, Guardian cannot and will not give any remediation steps because at the time of discovery as there may not be any known remediation steps. It will be advised to the end user to search up their specific CVE that was found through the canonical security database to find whether or not they have listed any remediation steps. If they have listed any remediation steps, it is the sole discretion of the user to determine the next steps of action. This tool only provides the ability to search. It does not provide any advice as to what to do in the event of a discovered vulnerability.

### Database Dependency

Guardian relies on external, third-party databases (such as Canonical’s Ubuntu Security Notices) for vulnerability information. Guardian is not responsible for the accuracy, uptime, or completeness of these external resources.

### False Positives

Security scanning may occasionally result in 'False Positives.' Users are encouraged to verify findings manually before taking drastic remediation actions, such as deleting critical system files or disabling services.

# Engagement Overview & Operational Framework

In the event that a vulnerability or system anomaly is identified via the G-CVE or G-SEC, the event is immediately recorded to the local persistent logs and dispatched asynchronously to the user interface via the integration API, textSMS, or NTFY

Upon execution, the Guardian Security Suite initializes an outbound data request to establish tracking states. This design guarantees consistent telemetry reporting during long-running security tasks—such as full filesystem or cryptographic signature audits—which typically require an operational window of 2.5 to 4 hours depending on system constraints.

## Vulnerability Flagging & Database Integration

When a verified risk is surfaced by the G-CVE module:

* The identified Common Vulnerabilities and Exposures (CVE) identifier is highlighted in red within the continuous monitoring terminal interface.  
* A list detailing the technical threat vectors is displayed alongside the flag.  
* A direct hyperlink is appended to the log entry, mapping the vector directly to the vendor definitions for inspection.

## Remediation Protocols & Liability Scope

Due to the volatile and rapidly shifting nature of newly published exploits, the Guardian Security Suite operates strictly as an auditing and discovery tool. 

#  Guardian Vault

The G-Vault module is a terminal-driven cryptographic storage manager built for maximum stealth, persistent metadata integrity, and anti-forensic asset handling. By utilizing a proprietary container architecture and volatile memory execution, G-Vault guarantees that secured data remains invisible and completely irretrievable post-purge.

## Proprietary Header Injection & Asset Architecture

* Metadata Persistence: G-Vault bypasses standard extended attributes (xattr) to prevent data loss during cross-platform transfers. It dynamically manipulates the binary stream to inject a custom signature (GUARDIAN\_META\_V1) directly into the payload.  
* Cryptographic Masking: Target assets are secured via AES-256 symmetric encryption and designated with the proprietary .grdn (Guardian) extension. This containerization fully masks the asset's underlying MIME-type and structural DNA from forensic indexing.

## Zero-Footprint Inspection & Sanitization

* Volatile Memory Execution: When a user inspects a .grdn file without permanent extraction, G-Vault establishes a secure transient state within the node's volatile memory (/dev/shm). The asset is decrypted strictly into this RAM disk. Upon viewer exiting the file, an immediate purge of the memory sector is executed, ensuring zero byte leakage to physical solid-state or hard disk drives.  
* Post-Encryption Shredding: Following successful cryptographic packaging, G-Vault initiates an optional sector-level sanitization protocol (shred \-u), repeatedly overwriting the original unencrypted source file to neutralize potential data recovery vectors.

