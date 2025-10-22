# Windows-PKI-Setup | Active Directory Certificate Services (AD CS) Automation Toolkit

## 📖 Overview
This repository contains a full suite of **PowerShell scripts** to automate the deployment, configuration, and management of **Microsoft Active Directory Certificate Services (AD CS)** for both **Root** and **Subordinate (Issuing)** Certificate Authorities.  

Designed for enterprise environments, this toolkit ensures secure, consistent, and fully auditable PKI deployment — from initial installation to ongoing maintenance and certificate lifecycle management.

---

## ✨ Key Features
- 🧱 Automated setup for **Root CA** and **Subordinate CA**
- ⚙️ Complete AD CS role installation and configuration
- 🔁 Automated **CRL (Certificate Revocation List)** and **AIA/CDP path** setup
- 🧩 Certificate template management and publication
- 🗄️ Policy configuration (validity periods, renewal, CRL intervals)
- 🧾 Logging and change tracking for compliance auditing
- 🔒 Secure CA hierarchy with **offline Root CA** support
- 🪪 Streamlined Sub CA enrollment from the Root CA
- 🚀 Modular and reusable PowerShell scripts with parameterized logic

---

## ⚙️ System Requirements

| Requirement | Minimum |
|--------------|----------|
| **OS** | Windows Server 2019 / 2022 / 2025 |
| **PowerShell** | Version 5.1 or later |
| **Roles** | AD CS, AD DS (optional), DNS |
| **Privileges** | Must be executed as Administrator |
| **Network** | Connectivity between Sub CAs and Root CA (or manual import path for offline root) |
| **CA Architecture** | Two-tier PKI (Root CA + Subordinate CA) |

---

## 🧩 Solution Overview

| Parameter | Value |
|------------|--------|
| **Solution Name** | AD CS Root & Subordinate CA Automation Toolkit |
| **Scope** | Active Directory-integrated PKI deployments |
| **Core Concept** | Modular PowerShell automation for secure CA provisioning and lifecycle management |
| **Primary Use Case** | Automated setup of Root and Sub CAs for enterprises and lab environments |

---

## 🗂️ Folder & Script Structure

### 📁 Root_CA
| Script | Description |
|---------|--------------|
| **install_root-ca.ps1** | Installs and configures an **offline Root Certificate Authority**, including root key generation and certificate policy configuration. |
| **configure_crl_aia_root.ps1** | Sets **CRL distribution points** and **AIA paths** for the Root CA, ensuring proper publication of revocation data. |
| **backup_root-ca.ps1** | Automates Root CA private key, certificate, and configuration backup for offline storage. |
| **publish_root-certificate.ps1** | Publishes the Root CA certificate to AD or shared folder for Sub CA enrollment. |

---

### 📁 Sub_CA
| Script | Description |
|---------|--------------|
| **install_sub-ca.ps1** | Installs and configures an **Issuing CA**, importing the Root CA certificate, and applying custom CA policy. |
| **request_sub-ca_certificate.ps1** | Creates a **certificate signing request (CSR)** to be signed by the Root CA. |
| **install_signed_sub-ca_certificate.ps1** | Imports and activates the signed Sub CA certificate from the Root CA. |
| **configure_crl_aia_sub.ps1** | Configures the Sub CA’s **CRL and AIA** publication points. |
| **configure_templates.ps1** | Enables, duplicates, and publishes custom **certificate templates** for users, computers, and services. |
| **enable_autoenrollment.ps1** | Configures Group Policy and permissions for **certificate auto-enrollment** within the domain. |
| **backup_sub-ca.ps1** | Performs automated backup of the Sub CA’s keys, database, and configuration. |

---

## 🚀 Execution Flow Example

Typical execution sequence for setting up a new PKI hierarchy:

```powershell
# Step 1: Offline Root CA Setup
.\Root_CA\install_root-ca.ps1
.\Root_CA\configure_crl_aia_root.ps1
.\Root_CA\publish_root-certificate.ps1

# Step 2: Online Subordinate CA Setup
.\Sub_CA\install_sub-ca.ps1
.\Sub_CA
equest_sub-ca_certificate.ps1
# -> Sign CSR on Root CA and import
.\Sub_CA\install_signed_sub-ca_certificate.ps1
.\Sub_CA\configure_crl_aia_sub.ps1

# Step 3: Post-Setup Configuration
.\Sub_CA\configure_templates.ps1
.\Sub_CA\enable_autoenrollment.ps1

# Step 4: Backup Procedures
.\Root_CAackup_root-ca.ps1
.\Sub_CAackup_sub-ca.ps1
```

---

## 🧾 Logging

All scripts include built-in logging that records:
- Execution timestamps  
- CA and CRL configuration changes  
- Errors and exceptions  
- Certificate operations and paths  

Logs are stored under:
```
C:\_it\0_CA_Root_Initial-Setup\ca-root-creation.log
C:\_it\0_CA_Sub_Initial-Setup\ca-sub-creation.log

```

---

## 🧠 Notes & Best Practices
- Always **disconnect the Root CA** after completing Sub CA signing to maintain offline security.
- Adjust the **CRL publication intervals** according to your security policy (default 1 week for Root, 1 day for Sub).
- Use **unique SAN entries** and **organization identifiers** in CSR requests.
- Ensure **NTAuth** and **Root certificates** are properly published in Active Directory.
- Regularly back up **CA private keys** and **configuration** to secure storage.

---

## 👤 Author

**Author:** Patrick Scherling  
**Solution:** Active Directory Certificate Services (AD CS) Automation Toolkit  
**Contact:** @Patrick Scherling  

---

> ⚡ *“Automate. Secure. Trust.”*  
> Part of Patrick Scherling’s IT automation suite for secure Windows Server PKI and Active Directory infrastructures.
