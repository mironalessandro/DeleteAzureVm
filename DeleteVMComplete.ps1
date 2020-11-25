Clear-Host
Write-Host "This script delete the vm and all the resources associated. You can decide to delete only one VM with option 0 or a vm pool with option 1. If you decide to delete a POOL the supported format is example-1 to example-4 and delete all the VM: example-1;example-2;example-3"
Write-Host -NoNewline -ForegroundColor Green "Single Vm (0) or Pooled VM (1)?:"
$SingleOrPooled = Read-Host

if($SingleOrPooled -eq "0")
{
    Write-Host -NoNewline -ForegroundColor Red "Please enter the VM name you would like to remove:"
    $VMName = Read-Host
    $vm = Get-AzVm -Name $VMName
    if ($vm) 
    {
        $RGName=$vm.ResourceGroupName
        Write-Host -ForegroundColor Cyan 'Resource Group Name is identified as-' $RGName
        $diagSa = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
        Write-Host -ForegroundColor Cyan 'Marking Disks for deletion...'
        $tags = @{"VMName"=$VMName; "Delete Ready"="Yes"}
        $osDiskName = $vm.StorageProfile.OSDisk.Name
        $datadisks = $vm.StorageProfile.DataDisks
        $ResourceID = (Get-Azdisk -Name $osDiskName).id
        New-AzTag -ResourceId $ResourceID -Tag $tags | Out-Null
        if ($vm.StorageProfile.DataDisks.Count -gt 0)
        {
            foreach ($datadisks in $vm.StorageProfile.DataDisks)
            {
                $datadiskname=$datadisks.name
                $ResourceID = (Get-Azdisk -Name $datadiskname).id
                New-AzTag -ResourceId $ResourceID -Tag $tags | Out-Null
            }
        }
        if ($vm.Name.Length -gt 9)
        {
            $i = 9
        }
        else
        {
            $i = $vm.Name.Length - 1
        }
        $azResourceParams = @{
         'ResourceName' = $VMName
         'ResourceType' = 'Microsoft.Compute/virtualMachines'
         'ResourceGroupName' = $RGName
        }
        $vmResource = Get-AzResource @azResourceParams
        $vmId = $vmResource.Properties.VmId
        $diagContainerName = ('bootdiagnostics-{0}-{1}' -f $vm.Name.ToLower().Substring(0, $i), $vmId)
        $diagSaRg = (Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $diagSa }).ResourceGroupName
        $saParams = @{
          'ResourceGroupName' = $diagSaRg
          'Name' = $diagSa
        }
        Write-Host -ForegroundColor Cyan 'Removing Boot Diagnostic disk..'
        if ($diagSa)
        {
            Get-AzStorageAccount @saParams | Get-AzStorageContainer | Where-Object {$_.Name-eq $diagContainerName} | Remove-AzStorageContainer -Force
        }
        else 
        {
            Write-Host -ForegroundColor Green "No Boot Diagnostics Disk found attached to the VM!"
        }
        Write-Host -ForegroundColor Cyan 'Removing Virtual Machine-' $VMName 'in Resource Group-'$RGName '...'
        $null = $vm | Remove-AzVM -Force
        Write-Host -ForegroundColor Cyan 'Removing Network Interface Cards, Public IP Address(s) used by the VM...'
        foreach($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id)
        {
           $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
           Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force
           foreach($ipConfig in $nic.IpConfigurations) 
           {
             if($ipConfig.PublicIpAddress -ne $null)
             {
                Remove-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force
             }
           }
        }
        Write-Host -ForegroundColor Cyan 'Removing OS disk and Data Disk(s) used by the VM..'
        Get-AzResource -tag $tags | Where-Object{$_.resourcegroupname -eq $RGName}| Remove-AzResource -force | Out-Null
        Write-Host -ForegroundColor Green 'Azure Virtual Machine-' $VMName 'and all the resources associated with the VM were removed sucesfully...'
    }
    else
    {
        Write-Host -ForegroundColor Red "The VM name entered doesn't exist in your connected Azure Tenant! Kindly check the name entered and restart the script with correct VM name..."
    }
}
if($SingleOrPooled -eq "1")
{
    Write-Host -NoNewline -ForegroundColor Green "VM Prefix name:"
    $prefix = Read-Host
    Write-Host -NoNewline -ForegroundColor Green "From number:"
    [uint16]$from = Read-Host 
    Write-Host -NoNewline -ForegroundColor Green "To number(excluded):"
    [uint16]$to = Read-Host
    if ($to -gt $from)
    {
        $string = "Delete from: " + $prefix + "-" + $from + " to " + $prefix + "-" + $to + " Continue? (yes or not):"
        Write-Host -NoNewline -ForegroundColor RED $string        
        $Continue = Read-Host
        if($Continue -eq "yes")
        {
            while($from -ne $to)
            {
		        $DeletedObject = "Deleting " + $prefix + "-" + $from 
                $ObjectToDelete = $prefix + "-" + $from
                Write-Host -ForegroundColor RED $DeletedObject
                $from++
                $VMName = $ObjectToDelete
                $vm = Get-AzVm -Name $VMName
                if ($vm) 
                {
                    $RGName=$vm.ResourceGroupName
                    Write-Host -ForegroundColor Cyan 'Resource Group Name is identified as' $RGName
                    $diagSa = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
                    Write-Host -ForegroundColor Cyan 'Marking Disks for deletion...'
                    $tags = @{"VMName"=$VMName; "Delete Ready"="Yes"}
                    $osDiskName = $vm.StorageProfile.OSDisk.Name
                    $datadisks = $vm.StorageProfile.DataDisks
                    $ResourceID = (Get-Azdisk -Name $osDiskName).id
                    New-AzTag -ResourceId $ResourceID -Tag $tags | Out-Null
                    if ($vm.StorageProfile.DataDisks.Count -gt 0)
                    {
                        foreach ($datadisks in $vm.StorageProfile.DataDisks)
                        {
                            $datadiskname=$datadisks.name
                            $ResourceID = (Get-Azdisk -Name $datadiskname).id
                            New-AzTag -ResourceId $ResourceID -Tag $tags | Out-Null
                        }
                    }
                    if ($vm.Name.Length -gt 9)
                    {
                        $i = 9
                    }
                    else
                    {
                        $i = $vm.Name.Length - 1
                    }
                    $azResourceParams = @{
                        'ResourceName' = $VMName
                        'ResourceType' = 'Microsoft.Compute/virtualMachines'
                        'ResourceGroupName' = $RGName
                        }
                        $vmResource = Get-AzResource @azResourceParams
                        $vmId = $vmResource.Properties.VmId
                        $diagContainerName = ('bootdiagnostics-{0}-{1}' -f $vm.Name.ToLower().Substring(0, $i), $vmId)
                        $diagSaRg = (Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $diagSa }).ResourceGroupName
                        $saParams = @{
                          'ResourceGroupName' = $diagSaRg
                          'Name' = $diagSa
                        }
                        Write-Host -ForegroundColor Cyan 'Removing Boot Diagnostic disk..'
                        if ($diagSa)
                        {
                            Get-AzStorageAccount @saParams | Get-AzStorageContainer | Where-Object {$_.Name-eq $diagContainerName} | Remove-AzStorageContainer -Force
                        }
                        else 
                        {
                            Write-Host -ForegroundColor Green "No Boot Diagnostics Disk found attached to the VM!"
                        }
                        Write-Host -ForegroundColor Cyan 'Removing Virtual Machine-' $VMName 'in Resource Group-'$RGName '...'
                        $null = $vm | Remove-AzVM -Force
                        Write-Host -ForegroundColor Cyan 'Removing Network Interface Cards, Public IP Address(s) used by the VM...'
                        foreach($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id)
                        {
                            $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
                            Remove-AzNetworkInterface -Name $nic.Name -ResourceGroupName $vm.ResourceGroupName -Force
                            foreach($ipConfig in $nic.IpConfigurations) 
                            {
                                if($ipConfig.PublicIpAddress -ne $null)
                                {
                                Remove-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $ipConfig.PublicIpAddress.Id.Split('/')[-1] -Force
                                }
                            }
                        }
                        Write-Host -ForegroundColor Cyan 'Removing OS disk and Data Disk(s) used by the VM..'
                        Get-AzResource -tag $tags | Where-Object{$_.resourcegroupname -eq $RGName}| Remove-AzResource -force | Out-Null
                        Write-Host -ForegroundColor Green 'Azure Virtual Machine-' $VMName 'and all the resources associated with the VM were removed sucesfully...'
                    }
                    else
                    {
                        Write-Host -ForegroundColor Red "The VM name entered doesn't exist in your connected Azure Tenant! Kindly check the name entered and restart the script with correct VM name..."
                    }                                
            }
        }
        else
        {
            Write-Host -ForegroundColor Green "Nothing Changed"
        }
    }
    else
    {
        Write-Host -ForegroundColor Red "Pay Attention. To value must be greater than From value. Please Restart the script "
    }
}
