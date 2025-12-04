:: 26.08.2024
:: Patrick Scherling
:: https://github.com/PScherling
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
powershell -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""C:\_psc\CA_Sub_Setup\1_CA_Managing\1_ca-server_cert-req-submission_final.ps1""' -Verb RunAs}"
pause

