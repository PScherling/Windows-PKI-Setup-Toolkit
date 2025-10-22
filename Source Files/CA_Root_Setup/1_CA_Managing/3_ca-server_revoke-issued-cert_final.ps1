<#
.SYNOPSIS
    Revokes one or more issued certificates from the local Certification Authority (CA).
	
.DESCRIPTION
    The **ca-server_revoke-issued-certificates.ps1** script provides a guided and semi-automated way 
    to revoke certificates that have been issued by a local or enterprise Certification Authority (CA).

    It uses the `certutil` command-line utility to query the CA’s internal database 
    and list all certificates currently marked as **Issued**, allowing administrators 
    to select one for revocation.  

    The script performs the following tasks:
    - Retrieves all issued certificates using:
      ```
      certutil -out "RequestId,RequesterName,CommonName,SerialNumber,NotBefore,NotAfter,Disposition" -view Log
      ```
    - Extracts key certificate information for each entry:
      - Request ID  
      - Requester Name  
      - Common Name  
      - Serial Number  
      - Validity Period (Start/End Dates)  
      - Issuance Status  
    - Displays a formatted and color-coded overview of all **Issued** certificates
    - Prompts the administrator to:
      - Select a certificate **Request ID** for revocation
      - Choose a valid **revocation reason** from a predefined list (based on RFC 5280 and CRL Reason Codes)
    - Executes the revocation command:
      ```
      certutil -revoke <SerialNumber> <ReasonCode>
      ```
    - Cleans up all temporary variables after execution

    Available revocation reasons:
    ```
    0. CRL_REASON_UNSPECIFIED           - Unspecified (default)
    1. CRL_REASON_KEY_COMPROMISE        - Key compromise
    2. CRL_REASON_CA_COMPROMISE         - CA compromise
    3. CRL_REASON_AFFILIATION_CHANGED   - Affiliation changed
    4. CRL_REASON_SUPERSEDED            - Superseded
    5. CRL_REASON_CESSATION_OF_OPERATION- Cessation of operation
    6. CRL_REASON_CERTIFICATE_HOLD      - Certificate hold
    8. CRL_REASON_REMOVE_FROM_CRL       - Remove from CRL
    9. CRL_REASON_PRIVILEGE_WITHDRAWN   - Privilege withdrawn
    10. CRL_REASON_AA_COMPROMISE        - Attribute authority compromised
    ```

    This tool provides a safe and controlled revocation workflow 
    for Root or Subordinate CA administrators without requiring direct database manipulation.
	
	Requirements:
    - Windows Server 2016 or newer  
    - PowerShell 5.1 or later  
    - Certification Authority role installed locally  
    - `certutil.exe` available in system path  
    - Administrative privileges on the CA server
	
.LINK
	https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/certutil  
    https://learn.microsoft.com/en-us/powershell/module/pkiclient  
    https://learn.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/manage-certification-authority
	https://github.com/PScherling
	
.NOTES
          FileName: ca-server_get-cert-status_final.ps1
          Solution: PKI Management Toolkit — Certificate Revocation Utility
          Author: Patrick Scherling
          Contact: @Patrick Scherling
          Primary: @Patrick Scherling
          Created: 2024-08-28
          Modified: 2025-09-30

          Version - 0.0.1 - () - Initial first attempt.
          Version - 0.1.0 - () - Publishing Version 1.
		  
		  To-Do:
			- Add option for batch revocation (multiple IDs)
			- Add optional CRL regeneration after revocation
			- Add logfile creation for audit compliance 


.Example
	PS> .\ca-server_revoke-issued-certificates.ps1
    Displays all currently issued certificates in the CA database 
    and allows the administrator to select one for revocation, 
    specifying the revocation reason interactively.

    PS> powershell.exe -ExecutionPolicy Bypass -File "C:\_it\CA_Management\ca-server_revoke-issued-certificates.ps1"
    Executes the certificate revocation process non-interactively 
    (e.g., as part of an administrative maintenance job or during CA cleanup).
#>
# Version number
$VersionNumber = "0.1.0"

$GetCerts = ""
$SumOfCerts = ""
$CertID = @()
$IssuedID = @()
$ReqName = @()
$IssuedReqName = @()
$CommonName = @()
$IssuedCommonName = @()
$SerialNumber = @()
$IssuedSN = @()
$StartDate = @()
$IssuedStartDate = @()
$EndDate = @()
$IssuedEndDate = @()
$Status = @()
$IssuedStatus = @()
$Input = ""
$CertSelected = "false"
$SumOfIssuedCerts = 0
$2Darray = @()
$ArrayLength = ""
$SNtoRevoke = ""
$Reason = ""


try{
    $GetCerts = certutil -out "RequestId,RequesterName,CommonName,SerialNumber,NotBefore,NotAfter,Disposition" -view Log
	
}
catch {
    Write-Warning "Could not get any issued Certificates from your CA."
    Read-Host -Prompt "Press any key to exit"

    $GetCerts = ""
    $SumOfCerts = ""
    $CertID = @()
    $IssuedID = @()
    $ReqName = @()
    $IssuedReqName = @()
    $CommonName = @()
    $IssuedCommonName = @()
    $SerialNumber = @()
    $IssuedSN = @()
    $StartDate = @()
    $IssuedStartDate = @()
    $EndDate = @()
    $IssuedEndDate = @()
    $Status = @()
    $IssuedStatus = @()
    $Input = ""
    $CertSelected = "false"
    $SumOfIssuedCerts = 0
    $2Darray = @()
    $ArrayLength = ""
    $SNtoRevoke = ""
    $Reason = ""

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
Write-Host "------------CA Revoking Certificates-------------"
Write-Host "##################################################" `n


for(($y = 0); $y -lt $SumOfCerts; $y++)
{
    if($Status[$y] -match "Issued")
    {
        Write-Host "Certificate Num."$y 
        Write-Host "ID:" $CertID[$y] " - Issuer:" $ReqName[$y] " - Issued for:" $CommonName[$y] " - SN:" $SerialNumber[$y]
        Write-Host "Valid from:" $StartDate[$y] " - Valid til:" $EndDate[$y]
        Write-Host "Issue Status: " $Status[$y] `n -ForegroundColor Green

        $IssuedID += $CertID[$y]
        $IssuedReqName += $ReqName[$y]
        $IssuedCommonName += $CommonName[$y]
        $IssuedSN += $SerialNumber[$y]
        $IssuedStartDate += $StartDate[$y]
        $IssuedEndDate += $EndDate[$y]
        $IssuedStatus += $Status[$y]


        $SumOfIssuedCerts++
    }
}

<#$IssuedID
$IssuedReqName
$IssuedCommonName
$IssuedSN
$IssuedStartDate
$IssuedEndDate
$IssuedStatus
$SumOfIssuedCerts#>


$2Darray = new-object 'object[,]' $SumOfIssuedCerts,7

for(($x = 0); $x -lt $SumOfIssuedCerts; $x++)
{
    $2Darray[$x,0] += $IssuedID[$x]
    $2Darray[$x,1] += $IssuedReqName[$x]
    $2Darray[$x,2] += $IssuedCommonName[$x]
    $2Darray[$x,3] += $IssuedSN[$x]
    $2Darray[$x,4] += $IssuedStartDate[$x]
    $2Darray[$x,5] += $IssuedEndDate[$x]
    $2Darray[$x,6] += $IssuedStatus[$x]

    #$2Darray
    #$ArrayLength = $x
}
#$2Darray[0,3]
#$2Darray
$ArrayLength = $x
#$ArrayLength

while($CertSelected -eq "false")
{
    $Input = Read-Host -Prompt " Enter Certificate ID that should be revoked"
    Write-Host "
    0. CRL_REASON_UNSPECIFIED - Nicht angegeben (Standard)
    1. CRL_REASON_KEY_COMPROMISE - Gefährdung des Schlüssels
    2. CRL_REASON_CA_COMPROMISE - Gefährdung der Zertifizierungsstelle
    3. CRL_REASON_AFFILIATION_CHANGED - Geänderte Zuordnung
    4. CRL_REASON_SUPERSEDED - Abgelöst
    5. CRL_REASON_CESSATION_OF_OPERATION - Einstellung des Vorgangs
    6. CRL_REASON_CERTIFICATE_HOLD - Pausiertes Zertifikat
    8. CRL_REASON_REMOVE_FROM_CRL - aus Zertifikatssperrliste entfernen
    9. CRL_REASON_PRIVILEGE_WITHDRAWN - Berechtigung zurückgezogen
    10. CRL_REASON_AA_COMPROMISE - AA-Kompromittiert
    "
    $Reason = Read-Host -Prompt " Choose a Reason from the list above (0/1/2.../10)"

    if($IssuedID -match $Input)
    {
        Write-Host " Revoking Certificate:" $Input
        $CertSelected = "true"

        for(($i = 0); $i -lt $ArrayLength; $i++)
        {
            if($2Darray[$i,0] -match $Input){
                $SNtoRevoke = $2Darray[$i,3]
            }
        }
        
    }
    elseif($IssuedID -notmatch $Input)
    {
        Write-Host " Wrong Input" -ForegroundColor Red
    }
}

if($CertSelected -eq "true")
{
    certutil -revoke $SNtoRevoke $Reason
}




$GetCerts = ""
$SumOfCerts = ""
$CertID = @()
$IssuedID = @()
$ReqName = @()
$IssuedReqName = @()
$CommonName = @()
$IssuedCommonName = @()
$SerialNumber = @()
$IssuedSN = @()
$StartDate = @()
$IssuedStartDate = @()
$EndDate = @()
$IssuedEndDate = @()
$Status = @()
$IssuedStatus = @()
$Input = ""
$CertSelected = "false"
$SumOfIssuedCerts = 0
$2Darray = @()
$ArrayLength = ""
$SNtoRevoke = ""
$Reason = ""