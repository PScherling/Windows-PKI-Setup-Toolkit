# Active Directory Certificate Services (AD CS) Automation Toolkit

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
| **1_ca-root-server-configuration_final.ps1** | Provides a fully automated and guided setup process for configuring a Root Certification Authority (Root CA). |

---

### 📁 Sub_CA
| Script | Description |
|---------|--------------|
| **1_ca-sub-server-configuration_final.ps1** | Provides a fully guided, automated setup process for preparing, installing, and configuring a subordinate CA server (Issuing CA) that is integrated into an existing PKI hierarchy with a Root CA. |

---

### 📁 Managing CA
| Script | Description |
|---------|--------------|
| **1_ca-server_cert-req-submission_final.ps1** | Automates the process of submitting pending certificate requests (.REQ files) to a Root or Subordinate Certificate Authority. |
| **2_ca-server_get-cert-status_final.ps1** | Automates the process of querying and parsing the local Certification Authority (CA) database to display a clear overview of all processed certificate requests. |
| **3_ca-server_revoke-issued-cert_final.ps1** | Provides a guided and semi-automated way to revoke certificates that have been issued by a local or enterprise Certification Authority (CA). |

---

## 🚀 Execution Flow Example

Typical execution sequence for setting up a new PKI hierarchy:

```powershell
# Step 1: Offline Root CA Setup
.\0_CA_Root_Initial-Setup\1_ca-root-server-configuration_final.ps1
```
<img width="1024" height="524" alt="image" src="https://github.com/user-attachments/assets/2b17d651-c7d7-44dc-bc1a-9ded528c79b1" />
<img width="1024" height="524" alt="image" src="https://github.com/user-attachments/assets/47c53fe5-429e-4990-a7af-34c21f92e0b9" />
<img width="1024" height="524" alt="image" src="https://github.com/user-attachments/assets/f2ecbeef-176d-4f55-9853-1a50bed0f8d2" />

```powershell
# Step 2: Online Subordinate CA Setup
.\0_CA_Sub_Initial-Setup\1_ca-sub-server-configuration_final.ps1
```
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/8b01443e-5408-48f2-8071-2c7f6f905d01" />
<img width="1024" height="529" alt="image" src="https://github.com/user-attachments/assets/de53a9dd-cefc-4084-b3e6-d435e7f84995" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/246beec5-e4dd-4138-a202-8eb05241efaf" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/5cff69f9-ee31-47f1-b892-f9ce8d8a6c70" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/fa6a4653-c0cd-4416-a423-dd014c280395" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/c112e470-d32a-4767-852e-7ffa356c91fa" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/d9ba6ed5-626d-46d4-a8e4-4232cc9ebeb1" />

**Do not close the PowerShell window!**
Copy the SubCA Cert-Request to the RootCA

```powershell
# Step 3: Issuing SubCA Request on RootCA
.\1_CA_Managing\1_ca-server_cert-req-submission_final.ps1
```
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/8f49c7da-869e-4596-9a02-73b021935204" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/a3a8e497-e4a4-41ab-ae2e-af860a951d82" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/0aa20ae7-aac3-4499-ac19-3d0b8fa67d24" />

Copy the issued CRL and CRT on RootCA to 'C:\Windows\System32\certsrv\CertEnroll'

**Continue on SubCA and press 'Enter'**
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/b90506d7-bec4-4d81-a71a-98c804d3246c" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/d81465f1-c2ca-4136-ad99-df5e9d8ad585" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/ac009d67-1c56-4b3f-8cb1-0ca99df57692" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/86f45c2f-3330-4448-bb2c-9d60da3fe058" />
<img width="1024" height="530" alt="image" src="https://github.com/user-attachments/assets/e24f0f84-ced6-43d3-90a6-afa67a574f11" />
<img width="239" height="110" alt="image" src="https://github.com/user-attachments/assets/ec41499b-b25e-4e4e-a66e-7d18c1e55440" />

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
