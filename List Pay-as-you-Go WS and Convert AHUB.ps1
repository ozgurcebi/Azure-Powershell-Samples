Add-AzureRmAccount
$VMs = Get-AzureRmVM
$vmOutput = @()
$VMs | ForEach-Object { 
  $tmpObj = New-Object -TypeName PSObject
  $tmpObj | Add-Member -MemberType Noteproperty -Name "VM Name" -Value $_.Name
  $tmpObj | Add-Member -MemberType Noteproperty -Name "OS version" -Value $_.StorageProfile.OsDisk.OsType
  $tmpObj | Add-Member -MemberType Noteproperty -Name "License Type" -Value $_.LicenseType
  $tmpObj | Add-Member -MemberType Noteproperty -Name "Resource Group"-Value $_.ResourceGroupName
  $vmOutput += $tmpObj | Format-List
}
$vmOutput 

Write-Host "AHUB aktif etmek istediğiniz Resource Grup ismini giriniz"  -ForegroundColor Green 
$RGName = Read-Host -Prompt "Resource Grup ismi"
Write-Host "AHUB aktif etmek istediğiniz VM'in ismini giriniz"  -ForegroundColor Green 
$VMName = Read-Host -Prompt "VM ismi"

$vm = Get-AzureRMVM -ResourceGroup "$RGName" -Name "$VMName"
$vm.LicenseType = "Windows_Server"
Update-AzureRMVM -ResourceGroupName $RGName -VM $vm

Write-Host "AHUB değişikliğini kontrol ediyoruz"  -ForegroundColor Green 
$VMs1 = Get-AzureRmVM
$vmOutput = @()
$VMs1 | ForEach-Object { 
  $tmpObj = New-Object -TypeName PSObject
  $tmpObj | Add-Member -MemberType Noteproperty -Name "VM Name" -Value $_.Name
  $tmpObj | Add-Member -MemberType Noteproperty -Name "OS version" -Value $_.StorageProfile.OsDisk.OsType
  $tmpObj | Add-Member -MemberType Noteproperty -Name "License Type" -Value $_.LicenseType
  $tmpObj | Add-Member -MemberType Noteproperty -Name "Resource Group"-Value $_.ResourceGroupName
  $vmOutput += $tmpObj
}
$vmOutput
