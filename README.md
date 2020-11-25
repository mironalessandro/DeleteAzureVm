# DeleteAzureVm
Delete VM with all associated resources - Single Vm or delete a pool Vm for WVD and not only
## Scope
If you try to delete a VM from the Azure portal you're just deleting the vm and not all the associated resources like disks, Network interface, boot diagnostic storage ecc.thats mean that you have a lot of orphaned resources that you still pay. This script is born to help us to delete completly the VM and all the resources. You can also delete a set of VM that have the same name with a number like example-1 example-2 ecc. You can find this type of configuration on the WVD.
## Configure
You can download DeleteVmComplete.ps1 and use it with PowerShell.
## Requirements
You must have Az module installed, you find here how to do it: https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.1.0
Once installed you must first login into your Azure account and on the correct Subscription.
Connect-AzAccount # Login with azure credential
Select-AzSubscription # Select the correct subscription.
## How to use
Start the script:
Step 1
Single Vm (0) or Pooled VM (1)?: You can select 0 for single VM delete and 1 for a pooled scenario.
If you select Single VM the only thing that you have to specify is the VM name.
If you select Pooled you have to specify the prefix the to value and the from value. If you want to delete a pool from example-1 to example-4 you must delete: example-1,example-2,example-3 and example-4 the the values will be prefix:example from 1 to 5(The to value will be exluded)

