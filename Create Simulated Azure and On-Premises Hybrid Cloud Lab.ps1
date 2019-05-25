Add-AzureRmAccount
Get-AzureRmSubscription
Write-Host "Lab kurulumunu yapmak istediğiniz Subscription ID'yi giriniz"  -ForegroundColor Green 
$serverName = Read-Host -Prompt "SubscriptionId giriniz"
$context=Get-AzureRmSubscription -SubscriptionId $serverName
Set-AzureRmContext $context

Write-Host "West Europe bölgesinde OnPrem-Site-RG-WE isimli Resource Group oluşturuyoruz"  -ForegroundColor Green 
$rg = New-AzureRMResourceGroup -Name OnPrem-Site-RG-WE -Location WestEurope

Write-Host "İlk Vnet'i oluşturup Adress Space olarak 10.11.0.0/22 belirliyoruz"  -ForegroundColor Green 
$vnet1 = New-AzureRmVirtualNetwork -ResourceGroupName $rg.ResourceGroupName -Name 'Vnet01' -AddressPrefix '10.11.0.0/22' -Location $rg.Location

Write-Host "FrontEnd ve BackEnd isimli Vnet Subnet'lerimizi oluşturuyoruz" -ForegroundColor Green 
Add-AzureRmVirtualNetworkSubnetConfig -Name 'FrontEnd' -VirtualNetwork $vnet1 -AddressPrefix '10.11.0.0/24'
Add-AzureRmVirtualNetworkSubnetConfig -Name 'BackEnd' -VirtualNetwork $vnet1 -AddressPrefix '10.11.1.0/24'OnPrem-Site-RG-WE
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet1
  
     ## İkinci RG,Vnet ve Subnet'i oluşturuyoruz. 
Write-Host "On_prem kaynaklarımızın benzerini Azure-Site-RG-WE isimli Resource Grup altında oluşturuyoruz"  -ForegroundColor Green 
$rg1 = New-AzureRMResourceGroup -Name Azure-Site-RG-WE -Location WestEurope
$vnet2 = New-AzureRmVirtualNetwork -ResourceGroupName $rg1.ResourceGroupName -Name 'Vnet02' -AddressPrefix '10.22.0.0/22' -Location $rg1.Location
Add-AzureRmVirtualNetworkSubnetConfig -Name 'FrontEnd' -VirtualNetwork $vnet2 -AddressPrefix '10.22.0.0/24'
Add-AzureRmVirtualNetworkSubnetConfig -Name 'BackEnd' -VirtualNetwork $vnet2 -AddressPrefix '10.22.1.0/24'
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet2

     ## Vnet Peering konfigurasyonunu yapıyoruz.
Write-Host "On_Prem ile Azure arasında Vnet Peering (S2S olarak düşünebilirsiniz) bağlantısı oluşturuyoruz"  -ForegroundColor Green 
     ## Peer VNet1 to VNet2
Add-AzureRMVirtualNetworkPeering -Name 'Vnet1ToVnet2' -VirtualNetwork $vnet1 -RemoteVirtualNetworkId $vnet2.Id

     ## Peer VNet2 to VNet1
Add-AzureRMVirtualNetworkPeering -Name 'Vnet2ToVnet1' -VirtualNetwork $vnet2 -RemoteVirtualNetworkId $vnet1.Id


Write-Host "Sunucularımız için 3389 portuna izin verecek kuralımızı yazıyoruz"  -ForegroundColor Green
$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name "AllowRDPRule" -Description "Allow RDP" `
    -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority "110" `
    -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389

Write-Host "On_Prem DC'mizi oluşturuyoruz"  -ForegroundColor Green 
Write-Host "Şifre min 8 karakter ve büyük,küçük harf , özel karakter /_ , sayı içermelidir"  -foregroundcolor yellow -backgroundcolor red 
$VMSize1 = "Standard_D2_v3"
$VMName1 = "DC01"
     ## On-Prem DC'mizi oluşturuyoruz. Local Admin olacak kullanıcı adı ve parola yı belirledikten sonra kurulum devam edecek.
$cred=Get-Credential -Message "DC01 sunucusu için yetkili hesap ismi ve şifresi belirleyiniz"
New-AzureRmVM -ResourceGroupName $rg.ResourceGroupName -Location $rg.Location -Size $VMSize1 -VirtualNetworkName Vnet01 -SubnetName FrontEnd -ImageName Win2016Datacenter -Name $VMName1 -Credential $cred 

$resourcegroup = "OnPrem-Site-RG-WE"
$vm = "DC01"
$shutdown_time = "1900"
$shutdown_timezone = "Turkey Standard Time"
$location = "West Europe"

$properties = @{
    "status" = "Enabled";
    "taskType" = "ComputeVmShutdownTask";
    "dailyRecurrence" = @{"time" = $shutdown_time };
    "timeZoneId" = $shutdown_timezone;
    "notificationSettings" = @{
        "status" = "Disabled";
        "timeInMinutes" = 30
    }
    "targetResourceId" = (Get-AzureRmVM -ResourceGroupName $resourcegroup -Name $vm).Id
}

Get-AzureRmResource  -Name DC01
Write-Host "ResourceId kısmını Resource Group Name dahil olacak şekilde kopyalayın " -ForegroundColor Green 
Write-Host "Örnek : /subscriptions/71fe6e08-0fbc-4eab-9824-6bc3d893e011/resourceGroups/OnPrem-Site-RG-WE" -ForegroundColor Green 
$ResourceIdName = Read-Host -Prompt "Kopyaladığınız ResourceId yapıştırın"
New-AzureRmResource -ResourceId ("$ResourceIdName/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzureRmContext).Subscription.Id, $resourceGroup, $vm) -Location (Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vm).Location -Properties $properties -Force

Get-AzureRmPublicIpAddress `
  -Name DC01 `
  -ResourceGroupName $rg.ResourceGroupName | Select IpAddress
  Write-Host "DC01 IP Adresi " -ForegroundColor Green 


Write-Host "Azure'daki uygulama sunucumuzu oluşturuyoruz"  -ForegroundColor Green
Write-Host "Şifre min 8 karakter ve büyük,küçük harf , özel karakter /_ , sayı içermelidir"  -foregroundcolor yellow -backgroundcolor red
$vmSize2="Standard_D2_v3"
$cred1=Get-Credential -Message "APP01 sunucusu için yetkili hesap ismi ve şifresi belirleyiniz"
New-AzureRmVM -ResourceGroupName $rg1.ResourceGroupName -Location $rg1.Location -Size $VMSize2 -VirtualNetworkName Vnet02 -SubnetName FrontEnd  -ImageName Win2016Datacenter -Name AzureApp01 -Credential $cred1 

$resourcegroup = "Azure-Site-RG-WE"
$vm = "AzureApp01"
$shutdown_time = "1900"
$shutdown_timezone = "Turkey Standard Time"
$location = "West Europe"

$properties = @{
    "status" = "Enabled";
    "taskType" = "ComputeVmShutdownTask";
    "dailyRecurrence" = @{"time" = $shutdown_time };
    "timeZoneId" = $shutdown_timezone;
    "notificationSettings" = @{
        "status" = "Disabled";
        "timeInMinutes" = 30
    }
    "targetResourceId" = (Get-AzureRmVM -ResourceGroupName $resourcegroup -Name $vm).Id
}

Get-AzureRmResource  -Name AzureApp01
Write-Host "ResourceId kısmını Resource Group Name dahil olacak şekilde kopyalayın " -ForegroundColor Green 
Write-Host "Örnek : /subscriptions/71fe6e08-0fbc-4eab-9824-6bc3d893e011/resourceGroups/OnPrem-Site-RG-WE" -ForegroundColor Green 
$ResourceIdName = Read-Host -Prompt "Kopyaladığınız ResourceId yapıştırın"
New-AzureRmResource -ResourceId ("$ResourceIdName/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzureRmContext).Subscription.Id, $resourceGroup, $vm) -Location (Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vm).Location -Properties $properties -Force

Get-AzureRmPublicIpAddress `
  -Name AzureApp01 `
  -ResourceGroupName $rg1.ResourceGroupName | Select IpAddress
  Write-Host "AzureApp01 IP Adresi " -ForegroundColor Green 

  Write-Host "Tebrikler !! Kurulum tamamlandı. Ekranda paylaşılan IP'ler ile sunculara uzak masaüstü 3389 üzerinden bağlanabilirsiniz"  -ForegroundColor Green 
  
 
