:: 26.08.2024
:: pscherling@eurofunk.com
:: 
:: 
:: 
:: Version 1.0
::
:: Changelog:
:: 
::
::
::
@echo off
powershell -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""C:\_it\CA_Sub_Setup\1_CA_Managing\2_ca-server_get-cert-status_final.ps1""' -Verb RunAs}"
pause