Param
(
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] 
    [String] 
    $VMName = "Specify only on Single VM",
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
    [String] 
    $SingleOrPooled = "Single",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] 
    [String] 
    $prefix = "example",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] 
    [int] 
    $From = "1",
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()] 
    [int] 
    $To = "1"
)
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    $connectionResult =  Connect-AzAccount -Tenant $servicePrincipalConnection.TenantID `
                             -ApplicationId $servicePrincipalConnection.ApplicationID   `
                             -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
                             -ServicePrincipal
    "Logged in."

}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
if (($SingleOrPooled -eq "Single") -or ($SingleOrPooled -eq "single") )
{
    $zvm = Get-AzVm -Name $VMName
    if ($vm) 
    {
        $RGName=$vm.ResourceGroupName
        'Resource Group Name is identified as-' + $RGName
        $diagSa = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
        'Marking Disks for deletion...'
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
        if ($diagSa)
        {
            Get-AzStorageAccount @saParams | Get-AzStorageContainer | Where-Object {$_.Name-eq $diagContainerName} | Remove-AzStorageContainer -Force
        }
        else 
        {
            "No Boot Diagnostics Disk found attached to the VM!"
        }
        'Removing Virtual Machine ' + $VMName + ' in Resource Group ' + $RGName + '...'
        $null = $vm | Remove-AzVM -Force
        'Removing Network Interface Cards, Public IP Address(s) used by the VM...'
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
        'Removing OS disk and Data Disk(s) used by the VM..'
        Get-AzResource -tag $tags | Where-Object{$_.resourcegroupname -eq $RGName}| Remove-AzResource -force | Out-Null
        'Azure Virtual Machine ' + $VMName + ' and all the resources associated with the VM were removed sucesfully...'        
    }
    else
    {
        "The VM name entered doesn't exist in your connected Azure Tenant! Kindly check the name entered and restart the script with correct VM name..."
    }
}
if (($SingleOrPooled -eq "Pooled") -or ($SingleOrPooled -eq "pooled") )
{
    #$zvm = Get-AzVm -Name $VMName
    if($To -ge $From)
    {
        while($from -ne $To)
        {
            $DeletedObject = "Deleting " + $prefix + "-" + $from 
            $ObjectToDelete = $prefix + "-" + $from
            $DeletedObject
            $from++
            $VMName = $ObjectToDelete
            $vm = Get-AzVm -Name $VMName
            if ($vm) 
            {
                $RGName=$vm.ResourceGroupName
                'Resource Group Name is identified as-' + $RGName
                $diagSa = [regex]::match($vm.DiagnosticsProfile.bootDiagnostics.storageUri, '^http[s]?://(.+?)\.').groups[1].value
                'Marking Disks for deletion...'
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
                if ($diagSa)
                {
                    Get-AzStorageAccount @saParams | Get-AzStorageContainer | Where-Object {$_.Name-eq $diagContainerName} | Remove-AzStorageContainer -Force
                }
                else 
                {
                    "No Boot Diagnostics Disk found attached to the VM!"
                }
                'Removing Virtual Machine ' + $VMName + ' in Resource Group ' + $RGName + '...'
                $null = $vm | Remove-AzVM -Force
                'Removing Network Interface Cards, Public IP Address(s) used by the VM...'
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
                'Removing OS disk and Data Disk(s) used by the VM..'
                Get-AzResource -tag $tags | Where-Object{$_.resourcegroupname -eq $RGName}| Remove-AzResource -force | Out-Null
                'Azure Virtual Machine ' + $VMName + ' and all the resources associated with the VM were removed sucesfully...'        
            }
            else
            {
                "The VM name entered doesn't exist in your connected Azure Tenant! Kindly check the name entered and restart the script with correct VM name..."
            }
        }
    }
    else 
    {
        "Pay Attention. TO value must be greater or equal than FROM value. Please set the parameters correctly and restart the script..."
    }
}