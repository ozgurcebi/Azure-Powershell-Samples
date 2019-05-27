# Azure PowerShell Script Samples
This repository contains useful Azure Powershell Scripts

# Requirements
Each script will describe its own dependencies for execution. Generally, you will need an Azure subscription as well as the script environments and any tools used by the script you wish to execute. This may include:

Azure PowerShell: How to install and configure Azure PowerShell  https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/

# Synopsis of Sample Scripts
**Create Simulated Azure and On-Premises Hybrid Cloud Lab.ps1 (TR)** This scenario creates 2 different RGs in Azure West Europe. Creates isolated Address Spaces and Subnets within each RG. Makes Vnet Peering among the created Subnets. Creates one virtual machine in each VNET. Gives Public IP information for servers created and you can connect RDP (3389) to servers with this information.Finally, it sets servers to automatically shut down at 19:00 Turkey Local Time.

**List Pay-as-you-Go WS and Convert AHUB.ps1 (TR)** This script lists the VM's under the subscription to the OS, License and RG type, and the VMs that generate the license cost through the Pay-as-you-go method.Allows you to use the advantage of AHUB on virtual servers you specify.
