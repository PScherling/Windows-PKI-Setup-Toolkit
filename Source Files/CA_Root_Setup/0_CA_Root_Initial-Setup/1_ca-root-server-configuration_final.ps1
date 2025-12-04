<#
.SYNOPSIS
    Automates the complete installation and configuration of a Standalone Root Certification Authority (CA) server.
	
.DESCRIPTION
    The **ca-root-server-configuration.ps1** script provides a fully automated and guided setup process 
    for configuring a **Root Certification Authority (Root CA)** in a new or existing Active Directory environment.  
    It is designed to ensure a consistent, secure, and repeatable CA deployment following best practices for PKI hierarchy creation.

    The script performs the following major tasks:
    - Gathers essential domain and host information interactively (e.g., domain name, hostname)
    - Defines default cryptographic parameters and CA configuration:
      ```
      Type: StandaloneRootCA
      Crypto Provider: RSA#Microsoft Software Key Storage Provider
      Key Length: 4096
      Hash Algorithm: SHA512
      Validity: 15 Years
      Database: D:\CertDB
      Logs: D:\CertLog
      ```
    - Executes the Root CA installation using:
      ```
      Install-AdcsCertificationAuthority
      ```
    - Configures Certificate Authority registry values for:
      - CRL and Delta CRL validity periods
      - Overlap periods
      - Validity periods for issued certificates
      - Signature algorithms
    - Defines the CRL Distribution Point (CDP) and AIA URLs based on a target subordinate CA (SubCA)
    - Automatically issues the first CRL and creates an export directory for certificate publication
    - Copies generated `.crl` and `.crt` files to a shared export folder (`D:\Export`)
    - Creates symbolic desktop links for CA management tools located in:
      ```
      C:\_psc\CA_Root_Setup\
      ```
    - Logs all actions, warnings, and errors to:
      ```
      C:\_psc\0_CA_Root_Initial-Setup\ca-root-creation.log
      ```

    This script serves as the **first stage** in a multi-tier PKI deployment:
    1. Root CA setup (this script)
    2. Subordinate CA setup (using a separate configuration script)
    3. Enterprise CA deployment and certificate publishing
	
	Requirements:
    - Windows Server 2019 or newer  
    - PowerShell 5.1 or later  
    - Active Directory Certificate Services (ADCS) role installed  
    - Administrative privileges on the host machine  
    - Secondary volume for CA database and log directories (recommended)  
    - Internet Information Services (IIS) for AIA/CRL publication (optional but recommended)
	
.LINK
	https://learn.microsoft.com/en-us/powershell/module/adcsdeployment/install-adcscertificationauthority  
    https://learn.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/install-the-certification-authority  
    https://learn.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/step-3-configure-the-ca
	https://github.com/PScherling
	
.NOTES
          FileName: ca-root-server-configuration.ps1
          Solution: Automated PKI Root CA Setup
          Author: Patrick Scherling
          Contact: @Patrick Scherling
          Primary: @Patrick Scherling
          Created: 2024-08-19
          Modified: 2025-09-30

          Version - 0.0.1 - () - Initial first attempt.
          Version - 0.1.0 - () - Publishing Version 1.
		  
		  To-Do:
			- Add automated verification for CA service status
			- Add validation for file share creation permissions
			- Integrate with SubCA provisioning scripts


.Example
	PS> .\ca-root-server-configuration.ps1
    Starts the interactive configuration of a Standalone Root CA.  
    Prompts for domain name and SubCA hostname, installs and configures 
    the Root CA, and applies all recommended security and validity parameters.

    PS> powershell.exe -ExecutionPolicy Bypass -File "C:\_psc\0_CA_Root_Initial-Setup\ca-root-server-configuration.ps1"
    Runs the Root CA setup automatically as part of a scripted PKI deployment, 
    logging all actions and creating the CA export and publication structure.


#>
# Version number
$VersionNumber = "0.1.0"

# Log file path
$logFile = "C:\_psc\0_CA_Root_Initial-Setup\ca-root-creation.log"
if(-not $logfile){
    New-Item -Name "ca-root-creation.log" -Path "C:\_psc\0_CA_Root_Initial-Setup" -ItemType "File"
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

$CAType = ""
$CryptoProvider = ""
$KeyLength = ""
$HashAlgorythm = ""
$DomainName = ""
$DomainNameArray = @()
$DNSuffixes = ""
$DCitem = ""
$CAHostname = ""
$ValidityPeriod = ""
$ValidityPeriodUnits = ""
$DatabaseDir = ""
$LogDir = ""
$response = ""
$FullDomainName = ""
$CAHostname = ""
$SubCAName = ""
$CRLDPUrl = ""
$AIAUrl = ""
$LinkPath = ""
$TargetPath = ""


# Start logging
Write-Log " Starting ca-root-server-configuration..."


while($response -ne "y" -and [string]::IsNullOrEmpty($DomainName)) {
    
	Write-Host "##################################################"
    Write-Host "----------Root CA Configuration Setup-------------"
    Write-Host "##################################################" `n
	#Hostname auslesen!
	$CAHostname = $env:COMPUTERNAME
	Write-Host "Your Hostname is: " $CAHostname
	Write-Host "--------------------------------------------------" `n
    $DomainName = Read-Host -Prompt "Enter Domain Name (like 'domain.at'): "
    Write-Host "--------------------------------------------------" `n
	$DomainNameArray = $DomainName.Split(".")
	
	while($DomainNameArray.Length -le 1 ) {
        Write-Warning "Domain Name is too short and not valid!"
		$DomainName = Read-Host -Prompt "Enter Domain Name (like 'domain.at'): "
		Write-Host "--------------------------------------------------" `n
		$DomainNameArray = $DomainName.Split(".")
    }
    while($DomainNameArray.Length -ge 6 ) {
        Write-Warning "Domain Name is far too long! Are you really sure about this?"
		$DomainName = Read-Host -Prompt "Enter Domain Name (like 'domain.at'): "
		Write-Host "--------------------------------------------------" `n
		$DomainNameArray = $DomainName.Split(".")
    }

	#Output for testing!
    #Write-Host $DomainNameArray
	
	foreach ($item in $DomainNameArray) {     
		# Erstelle einen dynamischen Variablennamen     
		$variableName = "DC_$($DomainNameArray.IndexOf($item))"          
		# Erstelle die Variable mit dem dynamischen Namen und weise ihr den Wert des aktuellen Elements zu 
		$DCitem = "DC="+$item
        New-Variable -Name $variableName -Value $DCitem
        #Write-Host "############" $DC_0
        
		#Write-Host $variableName
        Write-Host "Your DN Suffix" $variableName "is" $DCitem

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

    $CAType = "StandaloneRootCA"
	$CryptoProvider = "RSA#Microsoft Software Key Storage Provider"
	$KeyLength = "4096"
	$HashAlgorythm = "SHA512"
	$FullDomainName = $DNSuffixes
	$CAHostname = $CAHostname+"-CA"
	$ValidityPeriod = "Years"
	$ValidityPeriodUnits = "15"
	$DatabaseDir = "D:\CertDB"
	$LogDir = "D:\CertLog"

    Write-Host "Review of your Settings for your Root CA:
    Type: $CAType
    Crypto Provider: $CryptoProvider
    Key Length: $KeyLength
    Hash Algorythm: $HashAlgorythm
    Domain Suffixes: $FullDomainName
    CA-Hostname: $CAHostname
    Validity Period: $ValidityPeriod
    Validity Period Units: $ValidityPeriodUnits
    Database Location: $DatabaseDir
    Log Location: $LogDir"
    Write-Host "--------------------------------------------------" `n

	Write-Log " Your Hostname is: $($CAHostname)"
	Write-Log " Your Domain is: $($DomainName)"
	Write-Log " Type: $($CAType)"
    Write-Log " Crypto Provider: $($CryptoProvider)"
    Write-Log " Key Length: $($KeyLength)"
    Write-Log " Hash Algorythm: $($HashAlgorythm)"
    Write-Log " Domain Suffixes: $($FullDomainName)"
    Write-Log " CA-Hostname: $($CAHostname)"
    Write-Log " Validity Period: $($ValidityPeriod)"
    Write-Log " Validity Period Units: $($ValidityPeriodUnits)"
    Write-Log " Database Location: $($DatabaseDir)"
    Write-Log " Log Location: $($LogDir)"
	
    
    $response = Read-Host -Prompt "Press (y) to approve and continue or (a) to abort"
	Write-Log " User input: $($response)"
    if($response -eq "a") {
		Write-Log " User aborting configuration."
        foreach ($item in $DomainNameArray) {     
		    # Erheben der dynamischen Variablennamen     
		    $variableName = "DC_$($DomainNameArray.IndexOf($item))"          
		    # Lösche die Variable mit dem dynamischen Namen und weise ihr den Wert des aktuellen Elements zu 
		    remove-Variable -Name $variableName -Force
		    
	    }

		$CAType = ""
        $CryptoProvider = ""
        $KeyLength = ""
        $HashAlgorythm = ""
        $DomainName = ""
        $DomainNameArray = @()
        $DNSuffixes = ""
        $DCitem = ""
        $CAHostname = ""
        $ValidityPeriod = ""
        $ValidityPeriodUnits = ""
        $DatabaseDir = ""
        $LogDir = ""
		$FullDomainName = ""
		$CAHostname = ""
		$SubCAName = ""
		$CRLDPUrl = ""
		$AIAUrl = ""

        exit
    }

}

if ($response -eq "y") {
	Write-Log " User continues condiguration."
	Write-Log "############### Configuring RootCA ###############"
    Write-Host "--------------------------------------------------"
    Write-Host "############### Configuring RootCA ###############"
    Write-Host "--------------------------------------------------" `n
    
    Read-Host -Prompt "Press Enter key to continue"
	
    ### Configure RootCA ###
	try{
		Install-AdcsCertificationAuthority -CAType $CAType -CryptoProviderName $CryptoProvider -KeyLength $KeyLength -HashAlgorithmName $HashAlgorythm -CACommonName $CAHostname -CADistinguishedNameSuffix $FullDomainName -ValidityPeriod $ValidityPeriod -ValidityPeriodUnits $ValidityPeriodUnits -DatabaseDirectory $DatabaseDir -LogDirectory $LogDir -Force -ErrorAction Stop #-WhatIf
	}
	catch{
		Write-Warning "RootCA could not be configured!"
		Write-Log " RootCA could not be configured!"
		#### Clearing all Variables ####
		foreach ($item in $DomainNameArray) {     
			# Erheben der dynamischen Variablennamen     
			$variableName = "DC_$($DomainNameArray.IndexOf($item))"          
			# Lösche die Variable mit dem dynamischen Namen und weise ihr den Wert des aktuellen Elements zu 
			remove-Variable -Name $variableName -Force
			
		}

		$CAType = ""
		$CryptoProvider = ""
		$KeyLength = ""
		$HashAlgorythm = ""
		$DomainName = ""
		$DomainNameArray = @()
		$DNSuffixes = ""
		$DCitem = ""
		$CAHostname = ""
		$ValidityPeriod = ""
		$ValidityPeriodUnits = ""
		$DatabaseDir = ""
		$LogDir = ""
		$FullDomainName = ""
		$CAHostname = ""
		$SubCAName = ""
		$CRLDPUrl = ""
		$AIAUrl = ""
		
		exit
	}
	
	Write-Log " Root CA Server successfully configured."
    Write-Host "--------------------------------------------------"
	Write-Host "Root CA Server successfully configured" -ForegroundColor Green
	Write-Host "--------------------------------------------------"
	
	Write-Host "Now we are adapting some more settings..."
	Read-Host -Prompt "Press Enter key to continue"
	
	Write-Log " Executing DSConfigDN. 'CN=Configuration,$($FullDomainName)'"
	Write-Host "Executing DSConfigDN"
	#CERTUTIL -setreg CA\DSConfigDN "CN=Configuration,DC=contoso,DC=com"
	CERTUTIL -setreg CA\DSConfigDN "CN=Configuration,$($FullDomainName)"
	
	Write-Log " Executing CRLPeriod. 'CRLPeriod Weeks'"
	Write-Host "Executing CRLPeriod"
	CERTUTIL -setreg CA\CRLPeriod Weeks
	
	Write-Log " Executing CRLPeriod. 'CRLPeriodUnits 52'"
	Write-Host "Executing CRLPeriod"
	CERTUTIL -setreg CA\CRLPeriodUnits 52
	
	Write-Log " Executing CRLDeltaPeriod. 'CRLDeltaPeriods Days'"
	Write-Host "Executing CRLDeltaPeriod"
	CERTUTIL -setreg CA\CRLDeltaPeriods Days
	
	Write-Log " Executing CRLDeltaPeriodUnits. 'CRLDeltaUnits 0'"
	Write-Host "Executing CRLDeltaPeriodUnits"
	CERTUTIL -setreg CA\CRLDeltaUnits 0
	
	Write-Log " Executing CRLOverlapPeriods. 'CRLOverlapPeriods Weeks'"
	Write-Host "Executing CRLOverlapPeriods"
	CERTUTIL -setreg CA\CRLOverlapPeriods Weeks
	
	Write-Log " Executing CRLOverlapPeriodsUnits. 'CRLOverlapPeriodUnits 4'"
	Write-Host "Executing CRLOverlapPeriodsUnits"
	CERTUTIL -setreg CA\CRLOverlapPeriodUnits 4
	
	Write-Log " Executing ValidityPeriod. 'ValidityPeriod Years'"
	Write-Host "Executing ValidityPeriod"
	CERTUTIL -setreg CA\ValidityPeriod Years
	
	Write-Log " Executing ValidityPeriodUnits. 'ValidityPeriodUnits 10'"
	Write-Host "Executing ValidityPeriodUnits"
	CERTUTIL -setreg CA\ValidityPeriodUnits 10
	
	Write-Log " Executing DiscreteSignatureAlgorithm. 'DiscreteSignatureAlgorithm 1'"
	Write-Host "Executing DiscreteSignatureAlgorithm"
	CERTUTIL -setreg CA\csp\DiscreteSignatureAlgorithm 1
	
	Write-Log " Stopping CA Service."
	Write-Host "Stopping CA Service"
	net stop certsvc
	
	Write-Log " Starting CA Service."
	Write-Host "Starting CA Service"
	net start certsvc
	
	
	Write-Host "--------------------------------------------------" `n
    $SubCAName = Read-Host -Prompt "Enter Hostname of your Issuing CA (aka SubCA; like 'PSC-SubCA1'): "
	$SubCAFQDN = "$($SubCAName).$($DomainName)"
	$CRLDPUrl = "http://$SubCAFQDN/CertEnroll/<CaName><CRLNameSuffix><DeltaCRLAllowed>.crl"
	$AIAUrl = "http://$SubCAFQDN/CertEnroll/<ServerDNSName>_<CaName><CertificateName>.crt"
    Write-Host "--------------------------------------------------" `n
	Write-Host "Review of your Settings for CRL Distribution Point and AIA:
    CRL Distribution Point URL: $CRLDPUrl
    Authority Information Access Url: $AIAUrl
    "

	Write-Log "--------------------------------------------------"
	Write-Log " SubCA Name: $($SubCAName)"
	Write-Log " SubCA FQDN: $($SubCAFQDN)"
	Write-Log " CRL Distribution Point URL: $($CRLDPUrl)"
	Write-Log " Authority Information Access Url: $($AIAUrl)"


    Write-Host "--------------------------------------------------" `n
    Read-Host -Prompt "Press Enter key to continue"

	Write-Log " Setting new CRL Distribution Point."
	Write-Host "Setting new CRL Distribution Point"
	Add-CACRLDistributionPoint -Uri $CRLDPUrl -AddToCertificateCdp -AddToFreshestCrl -Force
	
	Write-Log " Setting Authority Information Access."
	Write-Host "Setting Authority Information Access"
	Add-CAAuthorityInformationAccess -Uri $AIAUrl -AddToCertificateAia -Force
	
	Write-Log " Stopping CA Service."
	Write-Host "Stopping CA Service"
	net stop certsvc
	
	Write-Log " Starting CA Service."
	Write-Host "Starting CA Service"
	net start certsvc
	
	Write-Host "--------------------------------------------------" `n
	Write-Log " Issuing new CRL."
	Write-Host "Issuing new CRL"
	Read-Host -Prompt "Press Enter key to continue"
	certutil -crl
	
	Write-Log " Creating Directory 'D:\Export' and Share it."
	Write-Host "Creating Directory 'D:\Export' and Share it"
    Read-Host -Prompt "Press Enter key to continue"
    try {
        New-Item -Path "D:\" -Name "Export" -ItemType "directory"
        Write-Host "--------------------------------------------------"
	    Write-Host "Directory successfully created" -ForegroundColor Green
	    Write-Host "--------------------------------------------------"
    }
    catch {
        Write-Warning "Directory Export on Volume 'D:\' could not be created. Please create it manually."
		Write-Log "ERROR: Directory Export on Volume 'D:\' could not be created. Please create it manually."
    }
    try {
        #$DomainAdmins = $DomainName+"\Domain Admins"
        New-SmbShare -name "Export" -Path "D:\Export" <#-FullAccess "$DomainAdmins"#> -ChangeAccess "Everyone"
        Write-Host "--------------------------------------------------"
	    Write-Host "Share successfully created" -ForegroundColor Green
	    Write-Host "--------------------------------------------------"
    }
    catch {
        Write-Warning "File Share with folder 'Export' could not be created. Please create it manually."
		Write-Log " ERROR: File Share with folder 'Export' could not be created. Please create it manually."
    }
	
	if(test-path -path "D:\Export")
	{
		Write-Log " Copy CRL from 'C:\Windows\System32\certsrv\CertEnroll' to 'D:\Export'."
		try {
			copy-item -Path "C:\Windows\System32\certsrv\CertEnroll\*.crl" -Destination "D:\Export" #-Recurse
			for ($i = 0; $i -le 100; $i=$i+10 ) {
				Write-Progress -Activity "File Copy in Progress" -Status "Copy Progress $i% Complete:" -PercentComplete $i
				Start-Sleep -Milliseconds 250
			}
			Write-Host "--------------------------------------------------"
			Write-Host "File successfully copied" -ForegroundColor Green
			Write-Host "--------------------------------------------------"
		}
		catch {
			Write-Warning "CRL File could not be copied to destination folder 'D:\Export'"
			Write-Log " ERROR: CRL File could not be copied to destination folder 'D:\Export'."
		}

		Write-Log " Copy CRT from 'C:\Windows\System32\certsrv\CertEnroll' to 'D:\Export'."
		try {
			copy-item -Path "C:\Windows\System32\certsrv\CertEnroll\*.crt" -Destination "D:\Export" #-Recurse
			for ($i = 0; $i -le 100; $i=$i+10 ) {
				Write-Progress -Activity "File Copy in Progress" -Status "Copy Progress $i% Complete:" -PercentComplete $i
				Start-Sleep -Milliseconds 250
			}
			Write-Host "--------------------------------------------------"
			Write-Host "File successfully copied" -ForegroundColor Green
			Write-Host "--------------------------------------------------"
		}
		catch {
			Write-Warning "RootCA Certificate File could not be copied to destination folder 'D:\Export'"
			Write-Log " ERROR: RootCA Certificate File could not be copied to destination folder 'D:\Export'."
		}
	}
	else {
		Write-Warning "
    Can not copy RootCA Certificate and issued CRL to the Export directory because it doesn't exist. 
    Please create the directory 'D:\Export' manually.
    Please copy those files manually from 'C:\Windows\System32\certsrv\CertEnroll' to 'D:\Export'"

		Write-Log "Can not copy RootCA Certificate and issued CRL to the Export directory because it doesn't exist. 
    Please create the directory 'D:\Export' manually.
    Please copy those files manually from 'C:\Windows\System32\certsrv\CertEnroll' to 'D:\Export'"

	}
	


	<#
	Creating Desktop Links for Managind the CA
	#>
	Write-Log " Creating Desktop Links for Managind the CA."
	
	try{
				
		$GetFiles = Get-ChildItem -File "C:\_psc\CA_Root_Setup\*" -Name -Include *.bat
		$SumOfFiles = $GetFiles.Count
		$LinkPath = "" 
		$TargetPath = ""
		
		foreach($File in $GetFiles) {
			
			#$FileList += $File
			$f = $File.Split(".")
			$FileName = $f[0]
			
			Write-Log " Crating 'C:\Users\Public\Desktop\$FileName.lnk'."

			$LinkPath = "C:\Users\Public\Desktop\$FileName.lnk"
			$TargetPath = "C:\_psc\CA_Root_Setup\$File"
			
			new-item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath
		}
	}
	catch{
		Write-Warning "Dekstop Links could not be created."
		Write-Log " ERROR: Dekstop Links could not be created."

	}
	
	Write-Log " Root CA Server configuration successfull."
	Write-Host "--------------------------------------------------"
	Write-Host "Root CA Server configuration successfull" -ForegroundColor Green
	Write-Host "--------------------------------------------------"
	
    #### Clearing all Variables ####
    foreach ($item in $DomainNameArray) {     
		# Erheben der dynamischen Variablennamen     
		$variableName = "DC_$($DomainNameArray.IndexOf($item))"          
		# Lösche die Variable mit dem dynamischen Namen und weise ihr den Wert des aktuellen Elements zu 
		remove-Variable -Name $variableName -Force
		
	}

	$CAType = ""
    $CryptoProvider = ""
    $KeyLength = ""
    $HashAlgorythm = ""
    $DomainName = ""
    $DomainNameArray = @()
    $DNSuffixes = ""
    $DCitem = ""
    $CAHostname = ""
    $ValidityPeriod = ""
    $ValidityPeriodUnits = ""
    $DatabaseDir = ""
    $LogDir = ""
	$FullDomainName = ""
	$CAHostname = ""
	$SubCAName = ""
	$CRLDPUrl = ""
	$AIAUrl = ""
}

