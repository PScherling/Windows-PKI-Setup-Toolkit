<#
.SYNOPSIS
    
.DESCRIPTION
    
.LINK

.NOTES
          FileName: ef-ca-server_cert-req-submission_final.ps1
          Solution: 
          Author: Patrick Scherling
          Contact: @Patrick Scherling
          Primary: @Patrick Scherling
          Created: 2024-08-26
          Modified: 2025-09-30

          Version - 0.0.1 - () - Initial first attempt.
          Version - 0.1.0 - () - Publishing Version 1.
		  
		  To-Do:
			- 


.Example

#>
# Version number
$VersionNumber = "0.1.0"

$GetReqFiles = @()
$SumOfReqFile = ""
$GetReqFiles = ""
$request = ""
$requestID = ""
$Hostname = ""
$CACommonName = ""
$RequestOK = "true"
$IssueOK = "true"
$ExportOK = "true"
$ExportFileName = ""
$FileSelected = "false"
$ReqFileList = @()


	<#
	
	CA Issuing a Cert Request
    Start
	
	#>


Write-Host "##################################################"
Write-Host "----Root CA Certificate Request and Submission----"
Write-Host "##################################################" `n

$Hostname = $env:COMPUTERNAME
$CACommonName = $Hostname+"-CA"
Write-Host "Your Hostname is: " $Hostname
Write-Host "CA CommonName is: " $CACommonName
Write-Host "Source and Destination Directory for your Files: D:\Export"
Write-Host "--------------------------------------------------" `n

#$GetReqFiles = (Get-ChildItem -File "D:\Export\*.req").BaseName
$GetReqFiles = Get-ChildItem -File "D:\Export\" -Name -Include *.req
$SumOfReqFile = $GetReqFiles.Count


#Write-Host $SumOfReqFile
#Write-Host $GetReqFiles

while($FileSelected -eq "false")
{
    foreach($ReqFile in $GetReqFiles) {
        #Write-Host $ReqFile
        $ReqFileList += $ReqFile
    }

    $Options = @()
    Write-Host "Select a Request File that should be submitted:"
    for(($x = 0); $x -lt $SumOfReqFile; $x++) {
        #Write-Host $x"." $GetReqFiles[$x]
        Write-Host $x"." $ReqFileList[$x]
        $Options += $x
    }
    Write-Host "e. Exit" `n
    
    $input = Read-Host "Please select an option (0/1/../e)"

    if($Options -contains $input){
            
        $FileSelected = "true"
		$GetRequest = $ReqFileList[$input]
        $FileName = $GetRequest#+".req"
		Write-Host "Selected Request File:" $FileName `n -ForegroundColor Yellow
		
		$ExportFileName = Read-Host -Prompt "Enter Name (like 'CA_Cert') for Certificate Export (We are going to export '.cer' and '.p7b')"

		
		# Submit certificate request to Internal CA
		try {
			$request = certreq -submit "D:\Export\$FileName" | Out-String | Select-String 'RequestId: (\d+)'
            #$RequestOK = "true"
		}
		catch {
			Write-Warning "ERROR submitting request"
            $RequestOK = "false"
			
		}

        if($RequestOK -eq "true")
        {
            Write-Host "--------------------------------------------------"
		    Write-Host "REQ File successfully submitted to RootCA" -ForegroundColor Green
		    Write-Host "--------------------------------------------------"

            
            # Issue requested certificate
		    try {
                $requestID = $request.Matches[0].Groups[1].Value.Trim()
			    Invoke-Command -ScriptBlock {certutil -resubmit $args[0]} -ArgumentList $requestID
                #$IssueOK = "true"
		    }
		    catch {
			    Write-Warning "ERROR issuing certificate"
                $IssueOK = "false"
			    
		    }

            if($IssueOK -eq "true")
            {
                Write-Host "--------------------------------------------------"
		        Write-Host "REQ File successfully issued by RootCA" -ForegroundColor Green
		        Write-Host "--------------------------------------------------"
                
                
		        # Exporting Certificate and Chain
		        try {
			        certreq -retrieve -config "$Hostname\$CACommonName" $requestID "D:\Export\$ExportFileName.cer" "D:\Export\$ExportFileName.p7b"
		            #$ExportOK = "true"
                    
                }
		        catch {
			        Write-Warning "ERROR exporting certificate"
                    $ExportOK = "false"
			        
		        }

                if($ExportOK -eq "true")
                {
                    Write-Host "--------------------------------------------------"
		            Write-Host "Certificate and Certificate Chain successfully exported" -ForegroundColor Green
		            Write-Host "--------------------------------------------------"
                }
				elseif($ExportOK -eq "false")
				{
					Write-Warning "Export was not successfull"
				}
            }
			elseif($IssueOK -eq "false")
			{
				Write-Warning "REQ File not successfully issued by RootCA"
			}



        }
        elseif($RequestOK -eq "false") {
            Write-Warning "REQ File not successfully submitted to RootCA"
        }
		

        
        if($RequestOK -eq "true" -and $IssueOK -eq "true" -and $ExportOK -eq "true")
        {
            Write-Host "--------------------------------------------------"
			Write-Host "Submission and Issuing Certificate Request was successfull" -ForegroundColor Green
            Write-Host "Submitted Request:" $FileName
            Write-Host "Exported Certificate: $ExportFileName.cer"
            Write-Host "Exported Certifcate Chain: $ExportFileName.p7b"
			Write-Host "--------------------------------------------------" `n
        }
        else
        {
            Write-Warning "Something went wrong!"

            $GetReqFiles = @()
            $SumOfReqFile = ""
            $GetReqFiles = ""
            $request = ""
            $requestID = ""
            $Hostname = ""
            $CACommonName = ""
            $RequestOK = "false"
            $IssueOK = "false"
            $ExportOK = "false"
            $ExportFileName = ""
            $ReqFileList = @()

            exit
        }
		
		
		
		
		
	}
	elseif($input -match 'e'){
        Write-Host "Exit Script..." -ForegroundColor Yellow

        $GetReqFiles = @()
        $SumOfReqFile = ""
        $GetReqFiles = ""
        $request = ""
        $requestID = ""
        $Hostname = ""
        $CACommonName = ""
        $RequestOK = "false"
        $IssueOK = "false"
        $ExportOK = "false"
        $ExportFileName = ""
        $FileSelected = "false"
        $ReqFileList = @()

        exit
    }
    elseif($Options -notcontains $input -or $input -notmatch 'e') {
		Write-Host "Wrong Input" `n -ForegroundColor Red
    }
}