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
<img width="1014" height="510" alt="image" src="https://github.com/user-attachments/assets/18bfcd0f-8f46-4c3c-a62f-d774ac2e5b57" />
<img width="1014" height="510" alt="image" src="https://github.com/user-attachments/assets/fc8642ae-f134-441d-9a4e-fe82819ad1e6" />
<img width="1014" height="718" alt="image" src="https://github.com/user-attachments/assets/2d1435f5-bad3-4fe2-ae93-b4934807dd13" />

```powershell
# Step 2: Online Subordinate CA Setup
.\0_CA_Sub_Initial-Setup\1_ca-sub-server-configuration_final.ps1
```
<img width="1015" height="613" alt="image" src="https://github.com/user-attachments/assets/3901fc60-9a6b-48cc-b683-e5344123dd36" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/a9b1a289-5909-487b-9eac-122e2cf647e6" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/6e985c07-4578-451b-b9dd-4755ae3879b6" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/3c90ae02-d1e2-4c8d-bb6f-236ca3571da8" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/517c8036-6900-4b99-9367-ac75fb6b9978" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/78568131-0193-4430-9693-e371377a5d21" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/50396836-42af-4a0a-876b-634e1e007058" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/d35362d6-8365-40ad-8a40-2ac9675e5385" />


**Do not close the PowerShell window!**
Copy the SubCA Cert-Request to the RootCA

```powershell
# Step 3: Issuing SubCA Request on RootCA
.\1_CA_Managing\1_ca-server_cert-req-submission_final.ps1
```
<img width="1014" height="718" alt="image" src="https://github.com/user-attachments/assets/1b74d26e-12e8-42e4-86ff-0dec83741ea8" />
<img width="1014" height="718" alt="image" src="https://github.com/user-attachments/assets/87240426-c56f-480d-994d-ac9fbe3bbb91" />
<img width="1014" height="718" alt="image" src="https://github.com/user-attachments/assets/d6cf7e51-6ec7-4f51-885d-04d2581bb00e" />


Copy the issued CRL and CRT on RootCA to 'C:\Windows\System32\certsrv\CertEnroll'

**Continue on SubCA and press 'Enter'**
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/6c012485-d0dd-489e-a831-cc62ccf8768a" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/da58f64c-4404-4eac-81ba-d3593120b3c7" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/f773ed8b-a620-40d9-8c25-61bfeeaee5a2" />
<img width="1014" height="624" alt="image" src="https://github.com/user-attachments/assets/5aa052f5-d099-4b77-b76e-f278408e8164" />
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
**Contact:** @Patrick Scherling  

---

> ⚡ *“Automate. Standardize. Simplify.”*  
> Part of Patrick Scherling’s IT automation suite for modern Windows Server infrastructure management.
