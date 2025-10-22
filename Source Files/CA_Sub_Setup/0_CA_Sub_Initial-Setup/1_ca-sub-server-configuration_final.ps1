<#
.SYNOPSIS
    Automates the full setup, installation, and configuration of a Subordinate (Issuing) Certification Authority (CA) in a two-tier PKI environment.
	
.DESCRIPTION
    This PowerShell script provides a fully guided, automated setup process for preparing, installing, and configuring a subordinate CA server 
    (Issuing CA) that is integrated into an existing PKI hierarchy with a Root CA. It performs all prerequisite checks, configurations, 
    and installations required to establish a properly functioning subordinate CA.

    The script includes:
    - Validation of domain membership and Root CA connectivity.
    - Creation of required export directories and network shares.
    - Secure connection establishment to the Root CA for certificate and CRL exchange.
    - Copying of Root CA certificates and CRLs to the subordinate CA.
    - Installation and configuration of the CA role, CA Web Enrollment, and Online Responder.
    - Automated generation and transfer of the certificate request file (.REQ) to the Root CA.
    - Guidance for importing the signed certificate chain (.P7B) from the Root CA.
    - Final CA service activation and cleanup of temporary setup data.

    All progress and actions are logged for traceability in the defined log file (default: `C:\_it\0_CA_Sub_Initial-Setup\ca-sub-creation.log`).
    The script is designed to be fault-tolerant and will revert configuration steps in case of errors or manual aborts.

.LINK
	https://github.com/PScherling
	
.NOTES
          FileName: ca-sub-server-configuration.ps1
          Solution: PKI Subordinate (Issuing) CA Automation
          Author: Patrick Scherling
          Contact: @Patrick Scherling
          Primary: @Patrick Scherling
          Created: 2024-08-21
          Modified: 2025-09-30

          Version - 0.0.1 - () - Initial first attempt.
          Version - 0.1.0 - () - Publishing Version 1.
		  
		  To-Do:
			- Implement automated RootCA certificate request signing integration.
            - Add enhanced error handling for remote share operations.
            - Integrate post-install configuration verification. 


.Example
	PS C:\> .\ca-sub-server-configuration.ps1
    Launches the automated setup for a subordinate CA. The script will:
    - Verify prerequisites (domain, RootCA, shares)
    - Configure directories and file shares
    - Copy RootCA cert/CRL
    - Install CA roles
    - Generate the SubCA request and transfer it to the RootCA
    - Await the signed certificate chain
    - Install and activate the CA
#>
# Version number
$VersionNumber = "0.1.0"

# Log file path
$logFile = "C:\_it\0_CA_Sub_Initial-Setup\ca-sub-creation.log"
if(-not $logfile){
    New-Item -Name "ca-sub-creation.log" -Path "C:\_it\0_CA_Sub_Initial-Setup" -ItemType "File"
}

# Function to log messages with timestamps
function Write-Log {
	param (
		[string]$Message
	)
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$logMessage = "[$timestamp] $Message"
	#Write-Output $logMessage
	$logMessage | Out-File -FilePath $logFile -Append
}

### Creating Variables ###
$DomainOK = "false"
$RootCANetOK = "false"
$RootCAShareOK = "false"
$ExportDirOK = "false"
$ExportShareOK = "false"
$RootCAShare = ""
$ExportDirCreated = "false"
$ExportShareCreated = "false"
$RootCAShareCreated = "false"
$RootCACRLCopy = "false"
$RootCACRTCopy = "false"
$CertAddStore = "false"
$CertPubDom = "false"
$CRLCopy = "false"
$CRTCopy = "false"
$P7BOK = "false"
$ConfCA = "true"
$P7BCertOK = "false"
$RootCAHostName = ""
$CARootCAName = ""

$PreCheckDone = "false"
$PreCheck = "false"
$PreConfDone = "false"
$CAInstDone = "false"

$CAType = ""
$CryptoProvider = ""
$KeyLength = ""
$HashAlgorythm = ""
$DomainName = ""
$DomainNameArray = @()
$DNSuffixes = ""
$DCitem = ""
$Hostname = ""
$CAHostname = ""
$ValidityPeriod = ""
$ValidityPeriodUnits = ""
$DatabaseDir = ""
$LogDir = ""
$response = ""
$FullDomainName = ""
$SubCAName = ""
$CRLDPUrl = ""
$AIAUrl = ""
$OutputCertRequestFile = ""
$RootCAIP = ""
$P7BCert = ""



	<#

	Start

	#>

# Start logging
Write-Log " Starting ca-sub-server-configuration..."

while($response -ne "y" -and $response -ne "a")
{
	Write-Warning "
	Make Sure you have installed and configured your RootCA first!
	If not, please exit this configuration and prepare your RootCA first."
	
	$response = Read-Host -Prompt "Press (y) if you want to coninue or (a) to abort"
	
    if($response -ne "a" -and $response -ne "y")
    {
        Write-Host "Wrong Input" -ForegroundColor Red
    }

	Write-Log " Make Sure you have installed and configured your RootCA first! If not, please exit this configuration and prepare your RootCA first."
	Write-Log " User input: $($response)"
}



### Starten mit Konfiguration der CA ###
if($response -eq "y") 
{
	
	### Starten mit Vorbereitung der SubCA ###
	
	Write-Host "##################################################"
    Write-Host "---------Issuing CA Installation Setup------------"
    Write-Host "##################################################" `n
    Write-Host "Starting with Prerequisite Checks" `n
	Write-Log "---------Issuing CA Installation Setup------------"
	Write-Log " Starting with Prerequisite Checks."
	
	<#
	
	Prerequisite Checks
	
	#>
	
	if($PreCheckDone -eq "false")
	{
		Write-Log " Checking Domain Membership."
		### Checking Domain Membership ###
		try 
		{
			$DomainName = Get-WMIObject Win32_ComputerSystem | Select-Object -ExpandProperty Domain
			
			if($DomainName -eq "WORKGROUP" -or $DomainName -eq "ARBEITSGRUPPE")
			{
				$DomainOK = "false"
				
			}
			else {
				$DomainOK = "true"
			}
		}
		catch 
		{
			$DomainOK = "false"
		}

		
		### Test RootCA Connection ###
		Write-Log " Test RootCA Connection."
		while($RootCANetOK -eq "false")
		{
			$RootCAIP = Read-Host -Prompt "Enter IP-Adress of your Root CA Server (Like 'x.x.x.x')"
			$RootCAHostName = Read-Host -Prompt "Enter Hostname of your RootCA"
			$CARootCAName = $RootCAHostName+"-CA"
			Write-Host "--------------------------------------------------"
			Write-Host "Testing Connection to RootCA Server..."
			Write-Host "--------------------------------------------------" `n
			$ConnectionTest = Test-NetConnection -ComputerName $RootCAIP | Select-Object PingSucceeded
			
			if($ConnectionTest -match "True") {
				$RootCANetOK = "true"
			}
			else{
				$RootCANetOK = "False"
			}
			
			
		}
		
		
		
		
		### Test RootCA Share connection ###
		Write-Log " Test RootCA Share connection."
		while($RootCAShareOK -eq "false")
		{
			Write-Host "--------------------------------------------------"
			Write-Host "Testing Connection to Share on RootCA Server..."
			Write-Host "--------------------------------------------------" `n
			Read-Host -Prompt "Press Enter to test connection"
			

			if(New-PSDrive -Name "CARootExport" -PSProvider FileSystem -Root "\\$RootCAIP\Export" -Credential "$RootCAIP\sysadmineuro"){
				$RootCAShareOK = "true"
				Remove-PSDrive -Name CARootExport -Force
			}
			else{
				$RootCAShareOK = "false"
			}
		}
		
		
		### Check if Export File Share does not exist ###
		Write-Log " Check if Export File Share does not exist."
		if(-Not ( Test-Path "D:\Export" ))
		{
			$ExportDirOK = "true"

		}
		else {
			$ExportDirOK = "false"

		}


		if(-Not ( get-SmbShare -name "Export" -ErrorAction Ignore ))
		{
			$ExportShareOK = "true"
		}
		else {
			$ExportShareOK = "false"
		}

		Write-Host "--------------------------------------------------"
		Write-Host "
Prerequisite Checks finished...
Check Results:"

		Write-Log " Prerequisite Checks finished."
		Write-Log " Results:"

		if($DomainOK -eq "true")
		{
			Write-Host "Domain Check: successfull" -ForegroundColor Green
			Write-Host "Issuing CA is Member of Domain $DomainName"
			Write-Log " Domain Check: successfull"
			Write-Log " Issuing CA is Member of Domain $($DomainName)"
		}
		elseif($DomainOK -eq "false")
		{
			Write-Host "Domain Check: not successfull" -ForegroundColor Red
			Write-Warning "Your Server is not in a valid domain. Please make sure, your Issuing CA Server has joined a valid domain before continueing with the configuration."
			Write-Log " Domain Check: not successfull"
			Write-Log " ERROR: Your Server is not in a valid domain. Please make sure, your Issuing CA Server has joined a valid domain before continueing with the configuration."
		}
		
		if($RootCANetOK -eq "true")
		{
			Write-Host "RootCA Network connection Check: successfull" -ForegroundColor Green
			Write-Host "RootCA IP-Adress:" $RootCAIP
			Write-Host "RootCA Hostname:" $RootCAHostName
			Write-Host "RootCA CommonName:" $CARootCAName
			Write-Log " RootCA Network connection Check: successfull"
			Write-Log " RootCA IP-Adress: $($RootCAIP)"
			Write-Log " RootCA Hostname: $($RootCAHostName)"
			Write-Log " RootCA CommonName: $($CARootCAName)"
		}
		elseif($RootCANetOK -eq "false")
		{
			Write-Host "RootCA Connection Check: not successfull" -ForegroundColor Red
			Write-Warning "Network connection to your RootCA Server could not be established."
			Write-Log " RootCA Connection Check: not successfull"
			Write-Log " ERROR: Network connection to your RootCA Server could not be established."
		}
		
		if($RootCAShareOK -eq "true")
		{
			Write-Host "RootCA FileShare Check: successfull" -ForegroundColor Green
			Write-Log " RootCA FileShare Check: successfull"
		}
		elseif($RootCAShareOK -eq "false")
		{
			Write-Host "RootCA FileShare Check: not successfull" -ForegroundColor Red
			Write-Warning "Connection to the Share on your RootCA Server could not be established."
			Write-Log " RootCA FileShare Check: not successfull"
			Write-Log " ERROR: Connection to the Share on your RootCA Server could not be established."
		}
		
		if($ExportDirOK -eq "true")
		{
			Write-Host "Export Directory Check: successfull" -ForegroundColor Green
			Write-Log "Export Directory Check: successfull"
		}
		elseif($ExportDirOK -eq "false")
		{
			Write-Host "Export Directory Check: not successfull" -ForegroundColor Red
			Write-Warning "A Directory 'Export' on Volume 'D:\' already exists."
			Write-Log " Export Directory Check: not successfull"
			Write-Log " ERROR: A Directory 'Export' on Volume 'D:\' already exists."
		}
		
		if($ExportShareOK -eq "true")
		{
			Write-Host "Local Export FileShare Check: successfull" -ForegroundColor Green
			Write-Log "Local Export FileShare Check: successfull"
		}
		elseif($ExportShareOK -eq "false")
		{
			Write-Host "Local Export FileShare Check: not successfull" -ForegroundColor Red
			Write-Warning "A FileShare for 'Export' already exists."
			Write-Log " Local Export FileShare Check: not successfull"
			Write-Log " ERROR: A FileShare for 'Export' already exists."
		}
		Write-Log "--------------------------------------------------"
		Write-Host "--------------------------------------------------" `n
		
		if($DomainOK -eq "false" -or $RootCANetOK -eq "false" -or $RootCAShareOK -eq "false" -or $ExportDirOK -eq "false" -or $ExportShareOK -eq "false")
		{
			Write-Warning "
    Overall Prerequisite Check is not successfull.
    Please correct any issues in order to beginn with Issuing CA installation and configuration."
			
			Write-Log " ERROR: Overall Prerequisite Check is not successfull. Please correct any issues in order to beginn with Issuing CA installation and configuration."

			exit
		}
		elseif($DomainOK -eq "true" -and $RootCANetOK -eq "true" -and $RootCAShareOK -eq "true" -and $ExportDirOK -eq "true" -and $ExportShareOK -eq "true")
		{
			Write-Host "--------------------------------------------------"
			Write-Host "Overall Prerequisite Check is successfull" -ForegroundColor Green
			Write-Host "--------------------------------------------------" `n
			Write-Log " Overall Prerequisite Check is successfull."
			
			$PreCheck = "true"
			$PreCheckDone = "true"
			
			#Securtity Check
			Read-Host -Prompt "Press Enter to begin with Prerequisite Configuration"
		}
	}
	
	elseif($PreCheckDone -eq "true")
	{
		Write-Warning "PreCheck Tasks already done."
		Write-Log " WARNING: PreCheck Tasks already done."
		$PreCheck = "true"
	}





	<#
	
	Prerequisite Configuration
	
	#>
	Write-Log " Starting Prerequisite Configuration..."
	if($PreCheck -eq "true" -and $PreCheckDone -eq "true" -and $PreConfDone -eq "false")
	{
		### Creating Export Directory ###
		Write-Log " Creating Export Directory."
		Write-Host "--------------------------------------------------"
		Write-Host "Creating Directory 'D:\Export'"
		Write-Host "--------------------------------------------------" `n
		if($ExportDirOK -eq "true")
		{
			Read-Host -Prompt "Press Enter key to continue"
			try {
				New-Item -Path "D:\" -Name "Export" -ItemType "directory"
			}
			catch {
				$ExportDirCreated = "false"
			}
			$ExportDirCreated = "true"
		}
		else {
			Write-Warning "Directory Export on Volume 'D:\' already exists."
			Write-Log " WARNING: Directory Export on Volume 'D:\' already exists."
			$ExportDirCreated = "false"
		}

		
		### Creating Export FileShare ###
		Write-Log " Creating Export FileShare."
		Write-Host "--------------------------------------------------"
		Write-Host "Creating FileShare on 'D:\Export'"
		Write-Host "--------------------------------------------------" `n
		if((Test-Path "D:\Export") -and $ExportShareOK -eq "true")
		{
			Read-Host -Prompt "Press Enter key to continue"
			try {
				$DomainAdmins = $DomainName+"\Domain Admins"
				New-SmbShare -name "Export" -Path "D:\Export" -FullAccess "$DomainAdmins" -ChangeAccess "Everyone"
			}
			catch {
				
				$ExportShareCreated = "false"
			}
			$ExportShareCreated = "true"
		}
		else {
			
			$ExportShareCreated = "false"
		}
		
		


		### Establish RootCA Share connection ###
		Write-Log " Establish RootCA Share connection."
		Write-Host "--------------------------------------------------"
		Write-Host "Establishing Connection with RootCA FileShare"
		Write-Host "--------------------------------------------------" `n
		if($RootCAShareOK -eq "true")
		{
			Read-Host -Prompt "Press Enter key to continue"
			try
			{
				New-PSDrive -Name "CARootExport" -PSProvider FileSystem -Root "\\$RootCAIP\Export" -Credential "$RootCAIP\sysadmineuro"
			}
			catch
			{
				
				$RootCAShareCreated = "false"
			}
			$RootCAShare = Get-PSDrive -Name "CARootExport" | select Name
			$RootCAShareCreated = "true"
		}
		else
		{
			Write-Warning "Connection with RootCA FileShare could not be established."
			Write-Log " WARNING: Connection with RootCA FileShare could not be established."
			$RootCAShareCreated = "false"
		}



		### Copy Files from Root CA to Sub CA ###
		Write-Log " Copy Files from Root CA to Sub CA."
		Write-Host "--------------------------------------------------"
		Write-Host "Downloading CRL and CRT Files from RootCA"
		Write-Host "--------------------------------------------------" `n
		if((test-path -path "D:\Export") -and $RootCAShare -match "CARootExport")
		{
			Read-Host -Prompt "Press Enter key to continue"
			try 
			{
				copy-item -Path "CARootExport:\*.crl" -Destination "D:\Export"
				for ($i = 0; $i -le 100; $i=$i+10 ) {
					Write-Progress -Activity "File Copy in Progress" -Status "Copy Progress $i% Complete:" -PercentComplete $i
					Start-Sleep -Milliseconds 250
				}
			}
			catch 
			{
				
				$RootCACRLCopy = "false"
			}
			try 
			{
				copy-item -Path "CARootExport:\*.crt" -Destination "D:\Export"
				for ($i = 0; $i -le 100; $i=$i+10 ) {
					Write-Progress -Activity "File Copy in Progress" -Status "Copy Progress $i% Complete:" -PercentComplete $i
					Start-Sleep -Milliseconds 250
				}

			}
			catch 
			{
				
				$RootCACRTCopy = "false"
			}
			$RootCACRLCopy = "true"
			$RootCACRTCopy = "true"
		}
		else 
		{
			Write-Warning "
			Directory 'D:\Export' does not exist or Connection with RootCA FileShare could not be established. 
			"
			Write-Log " WARNING: Directory 'D:\Export' does not exist or Connection with RootCA FileShare could not be established."
			$RootCACRLCopy = "false"
			$RootCACRTCopy = "false"
		}




		
		### Add RootCA Certificate to Certificate Store on SubCA ###
		Write-Log " Add RootCA Certificate to Certificate Store on SubCA."
		Write-Host "--------------------------------------------------"
		Write-Host "Adding the RootCA Certificate to the Certificate Store"
		Write-Host "--------------------------------------------------" `n
		if(test-path -path "D:\Export\*.crt")
		{
			Read-Host -Prompt "Press Enter key to continue"

			$RootCACertificate = Get-Item -Path "D:\Export\*.crt"
			
			try
			{
				certutil -addstore Root $RootCACertificate
			}
			catch{
				
				$CertAddStore = "false"
			}
			Write-Host "--------------------------------------------------" `n
			try
			{
				certutil -dspublish -f $RootCACertificate RootCA
			}
			catch{
				
				$CertPubDom = "false"
			}
			$CertAddStore = "true"
			$CertPubDom = "true"
		}
		else
		{
			Write-Warning "There is no certificate to import!"
			Write-Log " WARNING: There is no certificate to import!"
			$CertAddStore = "false"
			$CertPubDom = "false"
		}


		Write-Host "--------------------------------------------------"
		Write-Host "
Prerequisite Configuration finished...
Configuration Results:"

		Write-Log "--------------------------------------------------"
		Write-Log " Prerequisite Configuration finished."
		Write-Log " Results:"
		if($ExportDirCreated = "true")
		{
			Write-Host "Export directory creation: successfull" -ForegroundColor Green
			Write-Log " Export directory creation: successfull"
		}
		elseif($ExportDirCreated -eq "false")
		{
			Write-Host "Export directory creation: not successfull" -ForegroundColor Red
			Write-Warning "Directory Export on Volume 'D:\' could not be created."
			Write-Log " Export directory creation: not successfull"
			Write-Log " ERROR: Directory Export on Volume 'D:\' could not be created."
		}
		
		if($ExportShareCreated -eq "true")
		{
			Write-Host "Export FileShare creation: successfull" -ForegroundColor Green
			Write-Log " Export FileShare creation: successfull"
		}
		elseif($ExportShareCreated -eq "false")
		{
			Write-Host "Export FileShare creation: not successfull" -ForegroundColor Red
			Write-Warning "File Share with folder 'Export' could not be created."
			Write-Log " Export FileShare creation: not successfull"
			Write-Log " ERROR: File Share with folder 'Export' could not be created."
		}
		
		if($RootCAShareCreated -eq "true")
		{
			Write-Host "RootCA FileShare connection: successfull" -ForegroundColor Green
			Write-Log " RootCA FileShare connection: successfull"
		}
		elseif($RootCAShareCreated -eq "false")
		{
			Write-Host "RootCA FileShare connection: not successfull" -ForegroundColor Red
			Write-Warning "Connection to the Share on your RootCA Server could not be established."
			Write-Log " RootCA FileShare connection: not successfull"
			Write-Log " ERROR: Connection to the Share on your RootCA Server could not be established."
		}
		
		if($RootCACRLCopy -eq "true")
		{
			Write-Host "CRL download from RootCA: successfull" -ForegroundColor Green
			Write-Log " CRL download from RootCA: successfull"
		}
		elseif($RootCACRLCopy -eq "false")
		{
			Write-Host "CRL download from RootCA: not successfull" -ForegroundColor Red
			Write-Warning "CRL File could not be downloaded to destination folder 'D:\Export'"
			Write-Log " CRL download from RootCA: not successfull"
			Write-Log " ERROR: CRL File could not be downloaded to destination folder 'D:\Export'"
		}
		
		if($RootCACRTCopy -eq "true")
		{
			Write-Host "CRT download from RootCA: successfull" -ForegroundColor Green
			Write-Log " CRT download from RootCA: successfull"
		}
		elseif($RootCACRTCopy -eq "false")
		{
			Write-Host "CRT download from RootCA: not successfull" -ForegroundColor Red
			Write-Warning "CRT File could not be downloaded to destination folder 'D:\Export'"
			Write-Log " CRT download from RootCA: not successfull"
			Write-Log " ERROR: CRT File could not be downloaded to destination folder 'D:\Export'"
		}
		
		if($CertAddStore -eq "true")
		{
			Write-Host "Adding RootCA Certificate to Store: successfull" -ForegroundColor Green
			Write-Log " Adding RootCA Certificate to Store: successfull"
		}
		elseif($CertAddStore -eq "false")
		{
			Write-Host "Adding RootCA Certificate to Store: not successfull" -ForegroundColor Red
			Write-Warning "Certificate could not be added to store."
			Write-Log " Adding RootCA Certificate to Store: not successfull"
			Write-Log " ERROR: Certificate could not be added to store."
		}
		
		if($CertPubDom -eq "true")
		{
			Write-Host "Publish RootCA Certificate to domain: successfull" -ForegroundColor Green
			Write-Log " Publish RootCA Certificate to domain: successfull"
		}
		elseif($CertPubDom -eq "false")
		{
			Write-Host "Publish RootCA Certificate to domain: not successfull" -ForegroundColor Red
			Write-Warning "Certificate could not be published to domain."
			Write-Log " Publish RootCA Certificate to domain: not successfull"
			Write-Log " ERROR: Certificate could not be published to domain."
		}
		Write-Log "--------------------------------------------------"
		Write-Host "--------------------------------------------------" `n
		
		if($ExportDirCreated -eq "false" -or $ExportShareCreated -eq "false" -or $RootCAShareCreated  -eq "false" -or $RootCACRLCopy -eq "false" -or $RootCACRTCopy -eq "false" -or $CertAddStore -eq "false" -or $CertPubDom -eq "false")
		{
			Write-Warning "
    Overall Prerequisite Configuration was not successfull.
    Please correct any issues in order to beginn with Issuing CA installation and configuration." `n
			Write-Warning "Aborting Configuration. Reverting forgoing configuration..." `n
			Write-Host "Deleting the RootCA Certificate..."
			
			Write-Log " Overall Prerequisite Configuration was not successfull. Please correct any issues in order to beginn with Issuing CA installation and configuration."
			Write-Log " Aborting Configuration. Reverting forgoing configuration..."
			Write-Log " Deleting the RootCA Certificate..."
			try{
				$Certs = Get-ChildItem Cert:\LocalMachine\Root\* | select-object -Property Thumbprint, Subject

				foreach ($Cert in $Certs) {
					$Thumbprint = $Cert.Thumbprint
					$Subject = $Cert.Subject
					
					if($Subject -match $CARootCAName)
					{
						$stringToPost = $Thumbprint + " - " + $Subject
						Write-Host $stringToPost


						certutil -delstore Root $Thumbprint

					}
					else
					{
						Write-Warning "There is no RootCA Certificate in Store 'Root'."
						Write-Log " WARNING: There is no RootCA Certificate in Store 'Root'."
					}
				   
				}
			}
			catch{
				Write-Warning "RootCA Certificate could not be deleted."
				Write-Log " WARNING: RootCA Certificate could not be deleted."
			}

			Write-Host "Deleting DSPublish Entry..."
			Write-Log " Deleting DSPublish Entry..."
			try{
				certutil -dsdel $CARootCAName
			}
			catch{
				Write-Warning "Your RootCA Information could not be removed from Domain Store."
				Write-Log " WARNING: Your RootCA Information could not be removed from Domain Store."
			}
			
			Write-Host "Deleting RootCA CRL File..."
			Write-Log " Deleting RootCA CRL File..."
			try{
				Remove-Item -Path "D:\Export\*.crl" -Force
			}
			catch{
				Write-Warning "RootCA CRL File could not be deleted."
				Write-Log " WARNING: RootCA CRL File could not be deleted."
			}

			Write-Host "Deleting RootCA CRT File..."
			Write-Log " Deleting RootCA CRT File..."
			try{
				Remove-Item -Path "D:\Export\*.crt" -Force
			}
			catch{
				Write-Warning "RootCA CRT File could not be deleted."
				Write-Log " WARNING: RootCA CRT File could not be deleted."
			}

			Write-Host "Removing RootCA Share connection..."
			Write-Log " Removing RootCA Share connection..."
			try{
				Remove-PSDrive -Name CARootExport -Force
			}
			catch{
				Write-Warning "Connection to RootCA could not be deleted."
				Write-Log " WARNING: Connection to RootCA could not be deleted."
			}

			Write-Host "Removing Export FileShare..."
			Write-Log " Removing Export FileShare..."
			try{
				Remove-SmbShare -Name Export -Force
			}
			catch{
				Write-Warning "FileShare could not be deleted."    
				Write-Log " WARNING: FileShare could not be deleted."          
			}

			Write-Host "Deleting Export Directory..."
			Write-Log " Deleting Export Directory..."
			try{
				remove-item -Path "D:\Export" -Recurse -Force
			}
			catch{
				Write-Warning "Directory could not be deleted."
				Write-Log " WARNING: Directory could not be deleted."
			}
			
			### Setting Variables to Default Values ###
			$DomainOK = "false"
			$RootCANetOK = "false"
			$RootCAShareOK = "false"
			$ExportDirOK = "false"
			$ExportShareOK = "false"
			$RootCAShare = ""
			$ExportDirCreated = "false"
			$ExportShareCreated = "false"
			$RootCAShareCreated = "false"
			$RootCACRLCopy = "false"
			$RootCACRTCopy = "false"
			$CertAddStore = "false"
			$CertPubDom = "false"
			$CRLCopy = "false"
			$CRTCopy = "false"
			$P7BOK = "false"
			$ConfCA = "true"
			$P7BCertOK = "false"
			$RootCAHostName = ""
			$CARootCAName = ""

			$PreCheckDone = "false"
			$PreCheck = "false"
			$PreConfDone = "false"
			$CAInstDone = "false"

			$CAType = ""
			$CryptoProvider = ""
			$KeyLength = ""
			$HashAlgorythm = ""
			$DomainName = ""
			$DomainNameArray = @()
			$DNSuffixes = ""
			$DCitem = ""
			$Hostname = ""
			$CAHostname = ""
			$ValidityPeriod = ""
			$ValidityPeriodUnits = ""
			$DatabaseDir = ""
			$LogDir = ""
			$response = ""
			$FullDomainName = ""
			$SubCAName = ""
			$CRLDPUrl = ""
			$AIAUrl = ""
			$OutputCertRequestFile = ""
			$RootCAIP = ""
			$P7BCert = ""
			
			exit
		}
		elseif($ExportDirCreated -eq "true" -and $ExportShareCreated -eq "true" -and $RootCAShareCreated  -eq "true" -and $RootCACRLCopy -eq "true" -and $RootCACRTCopy -eq "true" -and $CertAddStore -eq "true" -and $CertPubDom -eq "true")
		{
			Write-Host "--------------------------------------------------"
			Write-Host "Overall Prerequisite Configuration was successfull" -ForegroundColor Green
			Write-Host "--------------------------------------------------" `n
			Write-Log " Overall Prerequisite Configuration was successfull"
			
			$PreConfDone = "true"
			
			#Securtity Check
			Read-Host -Prompt "Press Enter to begin with CA Installation"
		}
	}
	
	elseif($PreCheck -eq "false")
	{
		Write-Warning "PreCheck Tasks not successfull!"
		Write-Log " WARNING: PreCheck Tasks not successfull!"
		exit
	}





	<#
	
	CA Installation
	
	#>
	Write-Log " Starting CA Installation..."
	if($PreConfDone -eq "true")
	{
		### Make sure to continue with installation ###
		Write-Warning "
	If you begin with the CA installation, the installation and configuration can not be undone!
	Please make sure the Prerequisites could be done successfully.
	If you are aborting, all prerequisite progress will be lost and undone!
"
		$response = Read-Host -Prompt "Press (y) to approve and continue or (a) to abort"

		Write-Log "	If you begin with the CA installation, the installation and configuration can not be undone!
	Please make sure the Prerequisites could be done successfully.
	If you are aborting, all prerequisite progress will be lost and undone!"
		Write-Log " User input: $($response)"
		
		if($response -eq "a") 
		{
			Write-Warning "Aborting Configuration. Previous Configuration is going to be deleted"
			Write-Warning "Aborting Configuration. Reverting forgoing configuration..." `n
			Write-Host "Deleting the RootCA Certificate..."

			Write-Log " Aborting Configuration. Previous Configuration is going to be deleted."
			Write-Log " Aborting Configuration. Reverting forgoing configuration..."
			
			Write-Log " Deleting the RootCA Certificate."
			try{
				#Get-ChildItem Cert:\LocalMachine\Root\* | ft -AutoSize
				certutil -delstore Root $RootCACertificateID #ID muss noch ausgelesen werden
			}
			catch{
			}

			Write-Host "Deleting DSPublish Entry..."
			Write-Log " Deleting DSPublish Entry."
			try{
				#certutil -dspublish veröffentlichung aufheben
			}
			catch{
			}
			
			Write-Host "Deleting RootCA CRL File..."
			Write-Log " Deleting RootCA CRL File."
			try{
				Remove-Item -Path "D:\Export\*.crl" -Force
			}
			catch{
				Write-Warning "RootCA CRL File could not be deleted."
				Write-Log " WARNING: RootCA CRL File could not be deleted."
			}

			Write-Host "Deleting RootCA CRT File..."
			Write-Log " Deleting RootCA CRT File."
			try{
				Remove-Item -Path "D:\Export\*.crt" -Force
			}
			catch{
				Write-Warning "RootCA CRT File could not be deleted."
				Write-Log " WARNING: RootCA CRT File could not be deleted."
			}

			Write-Host "Removing RootCA Share connection..."
			Write-Log " Removing RootCA Share connection."
			try{
				Remove-PSDrive -Name CARootExport -Force
			}
			catch{
				Write-Warning "Connection to RootCA could not be deleted."
				Write-Log "Connection to RootCA could not be deleted."
			}

			Write-Host "Removing Export FileShare..."
			Write-Log " Removing Export FileShare."
			try{
				Remove-SmbShare -Name Export -Force
			}
			catch{
				Write-Warning "FileShare could not be deleted."  
				Write-Log " WARNING: FileShare could not be deleted."          
			}

			Write-Host "Deleting Export Directory..."
			Write-Log " Deleting Export Directory."
			try{
				remove-item -Path "D:\Export" -Recurse -Force
			}
			catch{
				Write-Warning "Directory could not be deleted."
				Write-Log " WARNING: Directory could not be deleted."
			}
			
			
			### Setting Variables to Default Values ###
			$DomainOK = "false"
			$RootCANetOK = "false"
			$RootCAShareOK = "false"
			$ExportDirOK = "false"
			$ExportShareOK = "false"
			$RootCAShare = ""
			$ExportDirCreated = "false"
			$ExportShareCreated = "false"
			$RootCAShareCreated = "false"
			$RootCACRLCopy = "false"
			$RootCACRTCopy = "false"
			$CertAddStore = "false"
			$CertPubDom = "false"
			$CRLCopy = "false"
			$CRTCopy = "false"
			$P7BOK = "false"
			$ConfCA = "true"
			$P7BCertOK = "false"
			$RootCAHostName = ""
			$CARootCAName = ""

			$PreCheckDone = "false"
			$PreCheck = "false"
			$PreConfDone = "false"
			$CAInstDone = "false"

			$CAType = ""
			$CryptoProvider = ""
			$KeyLength = ""
			$HashAlgorythm = ""
			$DomainName = ""
			$DomainNameArray = @()
			$DNSuffixes = ""
			$DCitem = ""
			$Hostname = ""
			$CAHostname = ""
			$ValidityPeriod = ""
			$ValidityPeriodUnits = ""
			$DatabaseDir = ""
			$LogDir = ""
			$response = ""
			$FullDomainName = ""
			$SubCAName = ""
			$CRLDPUrl = ""
			$AIAUrl = ""
			$OutputCertRequestFile = ""
			$RootCAIP = ""
			$P7BCert = ""
			
			exit

		}

		


		### Install SubCA Roles and Features ###
		Write-Host "##################################################"
		Write-Host "---------Issuing CA Installation Started----------"
		Write-Host "##################################################" `n
		Write-Log "---------Issuing CA Installation Started----------"
		try
		{
			Install-WindowsFeature Adcs-Cert-Authority, Adcs-Online-Cert, Adcs-Web-Enrollment -IncludeManagementTools
		}
		catch
		{
			Write-Warning "CA Role and Features could not be installed."
			Write-Log " ERROR: CA Role and Features could not be installed."
			exit
		}
		
		$CAInstDone = "true"
		
		
	}
	
	elseif($PreConfDone -eq "false")
	{
		Write-Warning "PreConfig Tasks not successfull!"
		Write-Log " WARNING: PreConfig Tasks not successfull!"
		exit
	}
	
	
	
	
	
	
	<#
	
	CA Konfiguration
	
	#>

	
	if($CAInstDone -eq "true")
	{
		Write-Host "--------------------------------------------------"
		Write-Host "############# Configuring Issuing CA #############"
		Write-Host "--------------------------------------------------" `n
		Write-Log "############# Configuring Issuing CA #############"
		
		### Hostname auslesen ###
		$Hostname = $env:COMPUTERNAME
		Write-Host "Your Hostname is: " $Hostname
		
        $User = $Env:UserName
		$CurrDom = $Env:UserDomain
		$DomUser = $CurrDom+"\"+$User
        Write-Host "Current Domain User is: " $DomUser
        
        $DomUser = get-credential -Credential $DomUser

		Write-Host "--------------------------------------------------" `n
		


		### DomainName in 'DC=' Splitten ###
		$DomainNameArray = $DomainName.Split(".")
		
		foreach ($item in $DomainNameArray) 
		{     
			# Erstelle einen dynamischen Variablennamen     
			$variableName = "DC_$($DomainNameArray.IndexOf($item))"          
			# Erstelle die Variable mit dem dynamischen Namen und weise ihr den Wert des aktuellen Elements zu 
			$DCitem = "DC="+$item
			New-Variable -Name $variableName -Value $DCitem

			Write-Host "Your DN Suffix" $variableName "is" $DCitem

			if($DomainNameArray.Length -eq 1) {
				$DNSuffixes = $DC_0
				#Write-Host $DNSuffixes
			}
			if($DomainNameArray.Length -eq 2) {
				$DNSuffixes = $DC_0+","+$DC_1
				#Write-Host $DNSuffixes
			}
			if($DomainNameArray.Length -eq 3) {
				$DNSuffixes = $DC_0+","+$DC_1+","+$DC_2
				#Write-Host $DNSuffixes
			}
			if($DomainNameArray.Length -eq 4) {
				$DNSuffixes = $DC_0+","+$DC_1+","+$DC_2+","+$DC_3
				#Write-Host $DNSuffixes
			}
			if($DomainNameArray.Length -eq 5 ) {
				$DNSuffixes = $DC_0+","+$DC_1+","+$DC_2+","+$DC_3+","+$DC_4
				#Write-Host $DNSuffixes
			}
			
		}

		Write-Host "Your Domain Name is: " $DomainName
		Write-Host "--------------------------------------------------" `n





		### CA Konfigurationswerte speichern und prüfen ###
		$CAType = "EnterpriseSubordinateCa"
		$CryptoProvider = "RSA#Microsoft Software Key Storage Provider"
		$KeyLength = "4096"
		$HashAlgorythm = "SHA512"
		$FullDomainName = $DNSuffixes
		$CAHostname = $Hostname+"-CA"
		$OutputCertRequestFile = "C:\$Hostname.$DomainName"+"_"+"$CAHostname.req"
		$DatabaseDir = "D:\CertDB"
		$LogDir = "D:\CertLog"

		Write-Host "Review of your Settings for your Issuing CA:
    Type: $CAType
    Crypto Provider: $CryptoProvider
    Key Length: $KeyLength
    Hash Algorythm: $HashAlgorythm
    Domain Suffixes: $FullDomainName
    CA-Hostname: $CAHostname
    Cert Request File: $OutputCertRequestFile
    Database Location: $DatabaseDir
    Log Location: $LogDir"
		Write-Host "--------------------------------------------------" `n

		Write-Log " Your Hostname is: $($Hostname)"
		Write-Log " Current Domain User is: $($DomUser)"
		Write-Log " Your Domain Name is: $($DomainName)"
		Write-Log " Type: $($CAType)"
    	Write-Log " Crypto Provider: $($CryptoProvider)"
    	Write-Log " Key Length: $($KeyLength)"
    	Write-Log " Hash Algorythm: $($HashAlgorythm)"
    	Write-Log " Domain Suffixes: $($FullDomainName)"
    	Write-Log " CA-Hostname: $($CAHostname)"
    	Write-Log " Cert Request File: $($OutputCertRequestFile)"
    	Write-Log " Database Location: $($DatabaseDir)"
    	Write-Log " Log Location: $($LogDir)"
		Write-Log "--------------------------------------------------"
		



		
		### Prpfen ob fortgefahren werden soll ###
		$response = Read-Host -Prompt "Press (y) to approve and continue or (a) to abort"
		Write-Log " User input: $($response)"
		if($response -eq "a") 
		{    
			### Clearing all Variables ###
			Write-Log " Aborting configuration."
			
			foreach ($item in $DomainNameArray) {     
				# Erheben der dynamischen Variablennamen     
				$variableName = "DC_$($DomainNameArray.IndexOf($item))"          
				# Lösche die Variable mit dem dynamischen Namen und weise ihr den Wert des aktuellen Elements zu 
				remove-Variable -Name $variableName -Force
				
			}
			
			Write-Host "Removing RootCA Share connection..."
			Write-Log " Removing RootCA Share connection."
			try{
				Remove-PSDrive -Name CARootExport -Force
			}
			catch{
				Write-Warning "Connection to RootCA could not be deleted."
				Write-Log " WARNING: Connection to RootCA could not be deleted."
			}
			
			Write-Host "Removing Export FileShare..."
			Write-Log " Removing Export FileShare."
			try{
				Remove-SmbShare -Name Export -Force
			}
			catch{
				Write-Warning "FileShare could not be deleted." 
				Write-Log " WARNING: FileShare could not be deleted."            
			}

			### Setting Variables to Default Values ###
			$DomainOK = "false"
			$RootCANetOK = "false"
			$RootCAShareOK = "false"
			$ExportDirOK = "false"
			$ExportShareOK = "false"
			$RootCAShare = ""
			$ExportDirCreated = "false"
			$ExportShareCreated = "false"
			$RootCAShareCreated = "false"
			$RootCACRLCopy = "false"
			$RootCACRTCopy = "false"
			$CertAddStore = "false"
			$CertPubDom = "false"
			$CRLCopy = "false"
			$CRTCopy = "false"
			$P7BOK = "false"
			$ConfCA = "true"
			$P7BCertOK = "false"
			$RootCAHostName = ""
			$CARootCAName = ""

			$PreCheckDone = "false"
			$PreCheck = "false"
			$PreConfDone = "false"
			$CAInstDone = "false"

			$CAType = ""
			$CryptoProvider = ""
			$KeyLength = ""
			$HashAlgorythm = ""
			$DomainName = ""
			$DomainNameArray = @()
			$DNSuffixes = ""
			$DCitem = ""
			$Hostname = ""
			$CAHostname = ""
			$ValidityPeriod = ""
			$ValidityPeriodUnits = ""
			$DatabaseDir = ""
			$LogDir = ""
			$response = ""
			$FullDomainName = ""
			$SubCAName = ""
			$CRLDPUrl = ""
			$AIAUrl = ""
			$OutputCertRequestFile = ""
			$RootCAIP = ""
			$P7BCert = ""
			

			exit
		}
		
		
		
		


		
		### Configure SubCA ###
		Write-Log " Configure SubCA."
		try
		{
			#Install-AdcsCertificationAuthority -CAType $CAType -CryptoProviderName $CryptoProvider -KeyLength $KeyLength -HashAlgorithmName $HashAlgorythm -CACommonName $CAHostname -CADistinguishedNameSuffix $FullDomainName -OutputCertRequestFile $OutputCertRequestFile -DatabaseDirectory $DatabaseDir -LogDirectory $LogDir -Force -ErrorAction Stop -WhatIf
			Write-Host "Configuring CA Role and Features..."
			Write-Log " Configuring CA Role and Features..."
			Install-AdcsCertificationAuthority -CAType $CAType -CryptoProviderName $CryptoProvider -KeyLength $KeyLength -HashAlgorithmName $HashAlgorythm -CACommonName $CAHostname -CADistinguishedNameSuffix $FullDomainName -OutputCertRequestFile $OutputCertRequestFile -DatabaseDirectory $DatabaseDir -LogDirectory $LogDir -Credential $DomUser -Force -ErrorAction Stop #-WhatIf
			Write-Host "Configuring CA Web Enrollment Role and Features..."
			Write-Log " Configuring CA Web Enrollment Role and Features..."
			Install-AdcsWebEnrollment -Credential $DomUser -Force -ErrorAction Stop #-WhatIf
			Write-Host "Configuring CA Online Responder Role and Features..."
			Write-Log " Configuring CA Online Responder Role and Features..."
			Install-AdcsOnlineResponder -Credential $DomUser -Force -ErrorAction Stop #-WhatIf
		}
		catch
		{
			
			$ConfCA = "false"
			
		}
		
		if($ConfCA -ne "false")
		{
			Write-Host "--------------------------------------------------"
			Write-Host "Issuing CA Server successfully configured" -ForegroundColor Green
			Write-Host "--------------------------------------------------"
			Write-Log " Issuing CA Server successfully configured."
			
			
			

			
			### Copy SubCA Req File to RootCA ###
			Write-Log " Copy SubCA Req File to RootCA."
			if(-Not (Test-Path "CARootExport:\$OutputCertRequestFile"))
			{
				try 
				{
					Write-Log " Copy '$($OutputCertRequestFile)' to 'CARootExport:\'."
					copy-item -Path "$OutputCertRequestFile" -Destination "CARootExport:\"
					for ($i = 0; $i -le 100; $i=$i+10 ) {
						Write-Progress -Activity "File Copy in Progress" -Status "Copy Progress $i% Complete:" -PercentComplete $i
						Start-Sleep -Milliseconds 250
					}
					Write-Host "--------------------------------------------------"
					Write-Host "SubCA REQ File successfully copied to RootCA" -ForegroundColor Green
					Write-Host "--------------------------------------------------"
					Write-Warning "
    Please make sure that you issue the request on the RootCA.
    As soon as you have exported the issued Request in a Certificate, you can continue with the next step."
				}
				catch 
				{
					Write-Warning "
    SubCA REQ File could not be uploaded to destination folder on RootCA.
    Please upload the .req file manually to your root CA."

					Write-Log " ERROR: SubCA REQ File could not be uploaded to destination folder on RootCA. Please upload the .req file manually to your root CA."
				}
			}
			elseif(Test-Path "CARootExport:\$OutputCertRequestFile")
			{
				Write-Warning "Request File already uploaded to RootCA."
				Write-Log " WARNING: Request File already uploaded to RootCA."
			}
			


			
			### Check for issued Certificate Chain ###
			Write-Log " Check for issued Certificate Chain."
			if($P7BOK -eq "false")
			{
				while(-Not ( Test-Path "CARootExport:\*.p7b" ))
				{
					Write-Warning "
    There is no exported Certificate Chain for your RootCA and SubCA.
    Please issue your request on your RootCA and export the issued request as 'p7b' certificate chain."

					Write-Log " ERROR: There is no exported Certificate Chain for your RootCA and SubCA. Please issue your request on your RootCA and export the issued request as 'p7b' certificate chain."
					
					Read-Host -Prompt "Press Enter key to check again"
					
				}
				
				if(Test-Path "CARootExport:\*.p7b")
				{
					$P7BOK = "true"
				}
			}
			
			




			
			### Copy Files from from Export to 'CertEnroll' ###
			Write-Log " Copy Files from from Export to 'CertEnroll'."
			Write-Host "--------------------------------------------------"
			Write-Host "Copy RootCA CRT and CRL File to 'CertEnroll' Store"
			Write-Host "--------------------------------------------------" `n
			if((test-path -path "D:\Export") -and (test-path -path "C:\Windows\System32\certsrv\CertEnroll"))
			{
				Read-Host -Prompt "Press Enter key to continue"
				try 
				{
					Write-Log " Copy CRL from 'D:\Export\' to 'C:\Windows\System32\certsrv\CertEnroll'."
					copy-item -Path "D:\Export\*.crl" -Destination "C:\Windows\System32\certsrv\CertEnroll"
					for ($i = 0; $i -le 100; $i=$i+10 ) 
					{
						Write-Progress -Activity "File Copy in Progress" -Status "Copy Progress $i% Complete:" -PercentComplete $i
						Start-Sleep -Milliseconds 250
					}
				}
				catch 
				{
					
					$CRLCopy = "false"
				}
				try 
				{
					Write-Log " Copy CRT from 'D:\Export\' to 'C:\Windows\System32\certsrv\CertEnroll'."
					copy-item -Path "D:\Export\*.crt" -Destination "C:\Windows\System32\certsrv\CertEnroll"
					for ($i = 0; $i -le 100; $i=$i+10 ) 
					{
						Write-Progress -Activity "File Copy in Progress" -Status "Copy Progress $i% Complete:" -PercentComplete $i
						Start-Sleep -Milliseconds 250
					}

				}
				catch 
				{
					
					$CRTCopy = "false"
				}
				$CRLCopy = "true"
				$CRTCopy = "true"
			}
			else 
			{
				Write-Warning "
				Directory 'D:\Export' or Directory 'C:\Windows\System32\certsrv\CertEnroll' does not exist. 
				"
				Write-Log " ERROR: Directory 'D:\Export' or Directory 'C:\Windows\System32\certsrv\CertEnroll' does not exist."
				$CRLCopy = "false"
				$CRTCopy = "false"
			}
			
			Write-Host "--------------------------------------------------"
			Write-Host "
SubCA Installation finished...
Install Results:
"
			Write-Log " SubCA Installation finished..."
			Write-Log " Results:"
			if($CRLCopy -eq "true")
			{
				Write-Host "CRL copy to 'CertEnroll': successfull" -ForegroundColor Green
				Write-Log " CRL copy to 'CertEnroll': successfull"
			}
			elseif($CRLCopy -eq "false")
			{
				Write-Host "CRL copy to 'CertEnroll': not successfull" -ForegroundColor Red
				Write-Warning "CRL File could not be copied to destination folder 'C:\Windows\System32\certsrv\CertEnroll'"
				Write-Log " CRL copy to 'CertEnroll': not successfull"
				Write-Log " CRL File could not be copied to destination folder 'C:\Windows\System32\certsrv\CertEnroll'"
			}
			
			if($CRTCopy -eq "true")
			{
				Write-Host "CRT copy to 'CertEnroll': successfull" -ForegroundColor Green
				Write-Log " CRT copy to 'CertEnroll': successfull" 
			}
			elseif($CRTCopy -eq "false")
			{
				Write-Host "CRT copy to 'CertEnroll': not successfull" -ForegroundColor Red
				Write-Warning "CRT File could not be copied to destination folder 'C:\Windows\System32\certsrv\CertEnroll'"
				Write-Log " CRT copy to 'CertEnroll': not successfull"
				Write-Log " CRT File could not be copied to destination folder 'C:\Windows\System32\certsrv\CertEnroll'"
			}
			Write-Log "--------------------------------------------------"
			Write-Host "--------------------------------------------------" `n
			
			if($CRLCopy -eq "false" -or $CRTCopy -eq "false")
			{
				Write-Warning "
    RootCA CRL and CRT File copy was not successfull.
    Please correct any issues in order to beginn with Issuing CA configuration." `n
				Write-Log " ERRIR: RootCA CRL and CRT File copy was not successfull. Please correct any issues in order to beginn with Issuing CA configuration."

				#exit
			}
			elseif($CRLCopy -eq "true" -and $CRTCopy -eq "true")
			{
				Write-Host "--------------------------------------------------"
				Write-Host "RootCA CRL and CRT File copy was successfull" -ForegroundColor Green
				Write-Host "--------------------------------------------------" `n
				Write-Log " RootCA CRL and CRT File copy was successfull"
				
				#Securtity Check
				Read-Host -Prompt "Press Enter to begin with CA Configuration"
			}









			### Copy Issued CA Certificate from RootCA to SubCA ###
			Write-Log " Copy Issued CA Certificate from RootCA to SubCA."
			if((-Not ( Test-Path "D:\Export\*.p7b" )) -and $P7BOK -eq "true")
			{
				Write-Host "--------------------------------------------------"
				Write-Host "Downloading P7B Certificate to Issuing CA"
				Write-Host "--------------------------------------------------" `n
				Read-Host -Prompt "Press Enter key to continue"
				try {
					copy-item -Path "CARootExport:\*.p7b" -Destination "D:\Export"
					for ($i = 0; $i -le 100; $i=$i+10 ) {
						Write-Progress -Activity "File Copy in Progress" -Status "Copy Progress $i% Complete:" -PercentComplete $i
						Start-Sleep -Milliseconds 250
					}
					Write-Host "--------------------------------------------------"
					Write-Host "P7B Certificate successfully copied" -ForegroundColor Green
					Write-Host "--------------------------------------------------"
					
				}
				catch {
					Write-Warning "P7B Certificate File could not be copied to destination folder 'D:\Export'"
					Write-Log " ERROR: P7B Certificate File could not be copied to destination folder 'D:\Export'"
				}
			}
			else {
				Write-Host "Certificate already exists." -ForegroundColor Yellow
				Write-Log " WARNING: Certificate already exists."
			}





			### Installing CA Certificate on SubCA ###
			Write-Log " Installing CA Certificate on SubCA."
			if(Test-Path "D:\Export\*.p7b")
			{
				$P7BCert = Get-ChildItem -Path D:\Export\*.p7b -Name
				Write-Host "Installing Certificate:" $P7BCert `n
				Read-Host "Press Enter to install certificate"
				try
				{
					#Import-Certificate -FilePath "D:\Export\$P7BCert" -CertStoreLocation "Cert:\LocalMachine\Root" -WhatIf
					certutil -installCert "D:\Export\$P7BCert"
					
					Write-Host "--------------------------------------------------"
					Write-Host "P7B Certificate successfully installed" -ForegroundColor Green
					Write-Host "--------------------------------------------------"
					
					Write-Host "Starting CA Service"
					Write-Log "Starting CA Service."
					net start certsvc
				}
				catch
				{
					Write-Warning "Certificate Chain could not be installed on your SubCA."
					Write-Log " ERROR: Certificate Chain could not be installed on your SubCA."
					$P7BCertOK = "false"
				}
				$P7BCertOK = "true"
			}
			elseif(-Not (Test-Path "D:\Export\*.p7b"))
			{
				Write-Warning "There is no Certificate Chain to install."
				Write-Log " ERROR: There is no Certificate Chain to install."
				$P7BCertOK = "false"
			}
		}
		elseif($ConfCA -eq "false")
		{
			Write-Warning "CA Configuration failed."
			Write-Log " ERROR: CA Configuration failed."
		}

	
	
	
	
		### Configuration End ###
		Write-Log " Configuration End."
		if( <#(Test-Path "CARootExport:\$OutputCertRequestFile") -and#> $P7BOK -eq "true" -and $P7BCertOK -eq "true" -and $ConfCA -eq "true" )
		{
			Write-Host "--------------------------------------------------"
			Write-Host "Installation and Configuration successfull" -ForegroundColor Green
			Write-Host "--------------------------------------------------"
			Write-Log "Installation and Configuration successfull."
			
			<#
			Creating Desktop Links for Managind the CA
			#>
			Write-Log " Creating Desktop Links for Managind the CA."
			
			try{
				
				$GetFiles = Get-ChildItem -File "C:\_it\CA_Sub_Setup\*" -Name -Include *.bat
				$SumOfFiles = $GetFiles.Count
				$LinkPath = "" 
				$TargetPath = ""
				
				foreach($File in $GetFiles) {
					
					#$FileList += $File
					$f = $File.Split(".")
					$FileName = $f[0]
					
					Write-Log " Crating Desktoplink 'C:\Users\Public\Desktop\$($FileName).lnk'."
					$LinkPath = "C:\Users\Public\Desktop\$FileName.lnk"
					$TargetPath = "C:\_it\CA_Sub_Setup\$File"
					
					new-item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath
				}
			}
			catch{
				Write-Warning "Dekstop Links could not be created."
				Write-Log " ERROR: Dekstop Links could not be created."
			}
			
			
			
			Write-Host "Clearing Temporary Data..."
			Write-Log " Clearing Temporary Data..."
			### Clearing all Variables ###
			foreach ($item in $DomainNameArray) {     
				# Erheben der dynamischen Variablennamen     
				$variableName = "DC_$($DomainNameArray.IndexOf($item))"          
				# Lösche die Variable mit dem dynamischen Namen und weise ihr den Wert des aktuellen Elements zu 
				remove-Variable -Name $variableName -Force
				
			}
			
			Write-Host "Removing RootCA Share connection..."
			Write-Log " Removing RootCA Share connection..."
			try{
				Remove-PSDrive -Name CARootExport -Force
			}
			catch{
				Write-Warning "Connection to RootCA could not be deleted."
				Write-Log " WARNING: Connection to RootCA could not be deleted."
			}
			
			Write-Host "Removing Export FileShare..."
			Write-Log " Removing Export FileShare..."
			try{
				Remove-SmbShare -Name Export -Force
			}
			catch{
				Write-Warning "FileShare could not be deleted."   
				Write-Log " WARNING: FileShare could not be deleted."         
			}

			### Setting Variables to Default Values ###
			$DomainOK = "false"
			$RootCANetOK = "false"
			$RootCAShareOK = "false"
			$ExportDirOK = "false"
			$ExportShareOK = "false"
			$RootCAShare = ""
			$ExportDirCreated = "false"
			$ExportShareCreated = "false"
			$RootCAShareCreated = "false"
			$RootCACRLCopy = "false"
			$RootCACRTCopy = "false"
			$CertAddStore = "false"
			$CertPubDom = "false"
			$CRLCopy = "false"
			$CRTCopy = "false"
			$P7BOK = "false"
			$ConfCA = "true"
			$P7BCertOK = "false"

			$PreCheckDone = "false"
			$PreCheck = "false"
			$PreConfDone = "false"
			$CAInstDone = "false"

			$CAType = ""
			$CryptoProvider = ""
			$KeyLength = ""
			$HashAlgorythm = ""
			$DomainName = ""
			$DomainNameArray = @()
			$DNSuffixes = ""
			$DCitem = ""
			$Hostname = ""
			$CAHostname = ""
			$ValidityPeriod = ""
			$ValidityPeriodUnits = ""
			$DatabaseDir = ""
			$LogDir = ""
			$response = ""
			$FullDomainName = ""
			$SubCAName = ""
			$CRLDPUrl = ""
			$AIAUrl = ""
			$OutputCertRequestFile = ""
			$RootCAIP = ""
			$P7BCert = ""
		}
			
		else
		{
			Write-Warning "Clearing Temporary Data..."
			Write-Log " Clearing Temporary Data..."
			### Clearing all Variables ###
			foreach ($item in $DomainNameArray) {     
				# Erheben der dynamischen Variablennamen     
				$variableName = "DC_$($DomainNameArray.IndexOf($item))"          
				# Lösche die Variable mit dem dynamischen Namen und weise ihr den Wert des aktuellen Elements zu 
				remove-Variable -Name $variableName -Force
				
			}
			
			Write-Host "Removing RootCA Share connection..."
			Write-Log "Removing RootCA Share connection..."
			try{
				Remove-PSDrive -Name CARootExport -Force
			}
			catch{
				Write-Warning "Connection to RootCA could not be deleted."
				Write-Log " WARNING: Connection to RootCA could not be deleted."
			}
			
			Write-Host "Removing Export FileShare..."
			Write-Log " Removing Export FileShare..."
			try{
				Remove-SmbShare -Name Export -Force
			}
			catch{
				Write-Warning "FileShare could not be deleted." 
				Write-Log " WARNING: FileShare could not be deleted."           
			}

			### Setting Variables to Default Values ###
			$DomainOK = "false"
			$RootCANetOK = "false"
			$RootCAShareOK = "false"
			$ExportDirOK = "false"
			$ExportShareOK = "false"
			$RootCAShare = ""
			$ExportDirCreated = "false"
			$ExportShareCreated = "false"
			$RootCAShareCreated = "false"
			$RootCACRLCopy = "false"
			$RootCACRTCopy = "false"
			$CertAddStore = "false"
			$CertPubDom = "false"
			$CRLCopy = "false"
			$CRTCopy = "false"
			$P7BOK = "false"
			$ConfCA = "true"
			$P7BCertOK = "false"

			$PreCheckDone = "false"
			$PreCheck = "false"
			$PreConfDone = "false"
			$CAInstDone = "false"

			$CAType = ""
			$CryptoProvider = ""
			$KeyLength = ""
			$HashAlgorythm = ""
			$DomainName = ""
			$DomainNameArray = @()
			$DNSuffixes = ""
			$DCitem = ""
			$Hostname = ""
			$CAHostname = ""
			$ValidityPeriod = ""
			$ValidityPeriodUnits = ""
			$DatabaseDir = ""
			$LogDir = ""
			$response = ""
			$FullDomainName = ""
			$SubCAName = ""
			$CRLDPUrl = ""
			$AIAUrl = ""
			$OutputCertRequestFile = ""
			$RootCAIP = ""
			$P7BCert = ""
		}
	}
	
	elseif($CAInstDone = "false")
	{
		Write-Warning "CA Role and Features not installed!"
		Write-Log " ERROR: CA Role and Features not installed!"
		exit
	}

}



### Aborting ###
elseif($response -eq "a")
{
	Write-Host "Exiting Setup..."
	Write-Log " Exiting Setup..."
	exit
}