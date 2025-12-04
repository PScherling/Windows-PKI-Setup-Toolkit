<#
.SYNOPSIS
    Retrieves and displays the current status of all issued, revoked, and denied certificates from a Certification Authority (CA).
	
.DESCRIPTION
    The **ca-server_get-cert-status_final.ps1** script automates the process of querying and parsing the local Certification Authority (CA) database
    to display a clear overview of all processed certificate requests — including their issuance status, validity period, and serial details.

    The script executes the following steps:
    - Uses the `certutil` command to query the CA database via:
      ```
      certutil -out "RequestId,RequesterName,CommonName,SerialNumber,NotBefore,NotAfter,Disposition" -view Log
      ```
    - Parses and extracts the following attributes for each certificate:
      - **Request ID**
      - **Requester Name**
      - **Common Name**
      - **Serial Number**
      - **Effective (Start) Date**
      - **Expiration (End) Date**
      - **Disposition / Status** (Issued, Revoked, Denied)
    - Summarizes all results in a formatted PowerShell output table
    - Color-codes results by status for improved readability:
      - **Green** – Issued
      - **Yellow** – Revoked
      - **Red** – Denied
    - Displays a simple summary of all certificates processed
    - Optionally allows the administrator to export or review CA status via console logs

    This script is designed for **Root and Subordinate CA administrators** to verify certificate activity and diagnose CA health,
    especially during PKI maintenance, issuance audits, or revocation checks.
	
	Requirements:
    - Windows Server 2016 or newer  
    - PowerShell 5.1 or later  
    - Certification Authority role installed locally  
    - Sufficient privileges to access CA database  
    - `certutil.exe` available in system path  
	
.LINK
	https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certutil  
    https://learn.microsoft.com/en-us/powershell/module/pkiclient  
    https://learn.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/manage-certification-authority
	https://github.com/PScherling

.NOTES
          FileName: ca-server_get-cert-status_final.ps1
          Solution: PKI Management Toolkit — CA Status Verification
          Author: Patrick Scherling
          Contact: @Patrick Scherling
          Primary: @Patrick Scherling
          Created: 2024-08-27
          Modified: 2025-09-30

          Version - 0.0.1 - () - Initial first attempt.
          Version - 0.1.0 - () - Publishing Version 1.
		  
		  To-Do:
			- Add export to CSV or HTML report
			- Add filtering for specific statuses (Issued, Revoked, Denied)
			- Add summary count by status


.Example
	PS> .\ca-server_get-cert-status_final.ps1
    Retrieves and lists all certificates from the CA database with their
    issuance state, validity dates, and serial numbers, displayed in color-coded format.

    PS> powershell.exe -ExecutionPolicy Bypass -File "C:\_psc\CA_Management\ca-server_get-cert-status_final.ps1"
    Executes the CA certificate status check script non-interactively 
    (for example, as part of a monitoring or audit job).
#>
# Version number
$VersionNumber = "0.1.0"

$GetCerts = ""
$SumOfCerts = ""
$CertID = @()
$ReqName = @()
$CommonName = @()
$SerialNumber = @()
$StartDate = @()
$EndDate = @()
$Status = @()


try{
    $GetCerts = certutil -out "RequestId,RequesterName,CommonName,SerialNumber,NotBefore,NotAfter,Disposition" -view Log
}
catch {
    Write-Warning "Could not get any issued, revoked or denied Certificates from your CA."
    Read-Host -Prompt "Press any key to exit"

    $GetCerts = ""
    $SumOfCerts = ""
    $CertID = @()
    $ReqName = @()
    $CommonName = @()
    $SerialNumber = @()
    $StartDate = @()
    $EndDate = @()
    $Status = @()

    exit
}




foreach($e in $GetCerts)
{
    if($e -match "Issued Request ID:")
    {
        $d = $e.Split(":")
        $k = $d[1].Split(" ")
        #$k[1]
        #Write-Host "-----"
        $f = [Convert]::ToInt32($k[1],16)
        #$f
        #Write-Host "------"

        $CertID += $f
        
    }
}

foreach($r in $GetCerts)
{
    
    if($r -match "Requester Name:")
    {
        $d = $r.Split(":")
        $k = $d[1].Split('"')
        $f = $k[1].Split(" ")
        #$f
        #Write-Host "------"
        
        $ReqName += $f
        
    }
    
}

foreach($t in $GetCerts)
{
    
    if($t -match "Issued Common Name:")
    {
        $d = $t.Split(":")
        $k = $d[1].Split('"')
        $f = $k[1].Split(" ")
        #$f
        #Write-Host "------"

        $CommonName += $f
        
    }
    
}

foreach($z in $GetCerts)
{
    
    if($z -match "Serial Number:")
    {
        $d = $z.Split(":")
        $k = $d[1].Split('"')
        $f = $k[1]
        <#if($f -match " ")
        {
            $f = "EMPTY"
        }#>
        #$f
        #Write-Host "------"
        
        $SerialNumber += $f
        
    }
    
}

foreach($i in $GetCerts)
{
    
    if($i -match "Certificate Effective Date:")
    {
        $d = $i.Split(":")
        $k = $d[1].Split(" ")
        $f = $k[1]
        #$f
        #Write-Host "------"
       
        $StartDate += $f
        
    }
    
}

foreach($i in $GetCerts)
{
    
    if($i -match "Certificate Expiration Date:")
    {
        $d = $i.Split(":")
        $k = $d[1].Split(" ")
        $f = $k[1]
        #$f
        #Write-Host "------"
       
        $EndDate += $f
        
    }
    
}

foreach($u in $GetCerts)
{
    
    if($u -match "Request Disposition:")
    {
        $d = $u.Split("--")
        $k = $d[2].Split(" ")
        $f = $k[1]
        #$f
        #Write-Host "------"
        $Status += $f
        
    }
    
}

$SumOfCerts = $CertID.Count


Write-Host "##################################################"
Write-Host "------------CA Status of Certificates-------------"
Write-Host "##################################################" `n


for(($x = 0); $x -lt $SumOfCerts; $x++)
{
    if($Status[$x] -match "Issued")
    {
        Write-Host "Certificate Num."$x 
        Write-Host "ID:" $CertID[$x] " - Issuer:" $ReqName[$x] " - Issued for:" $CommonName[$x] " - SN:" $SerialNumber[$x]
        Write-Host "Valid from:" $StartDate[$x] " - Valid til:" $EndDate[$x]
        Write-Host "Issue Status: " $Status[$x] `n -ForegroundColor Green
    }
    elseif($Status[$x] -match "Revoked")
    {
         Write-Host "Certificate Num."$x 
         Write-Host "ID:" $CertID[$x] " - Issuer:" $ReqName[$x] " - Issued for:" $CommonName[$x] " - SN:" $SerialNumber[$x]
         Write-Host "Valid from:" $StartDate[$x] " - Valid til:" $EndDate[$x]
         Write-Host "Issue Status: " $Status[$x] `n -ForegroundColor Yellow
    }
    elseif($Status[$x] -match "Denied")
    {
         Write-Host "Certificate Num."$x 
         Write-Host "ID:" $CertID[$x] " - Issuer:" $ReqName[$x] " - Issued for:" $CommonName[$x] " - SN:" $SerialNumber[$x]
         Write-Host "Valid from:" $StartDate[$x] " - Valid til:" $EndDate[$x]
         Write-Host "Issue Status: " $Status[$x] `n -ForegroundColor Red
    }
}

Read-Host -Prompt "Press any key to exit"


$GetCerts = ""
$SumOfCerts = ""
$CertID = @()
$ReqName = @()
$CommonName = @()
$SerialNumber = @()
$StartDate = @()
$EndDate = @()
$Status = @()

