# DeleteAzureVm
Delete VM with all associated resources - Single Vm or delete a pool Vm for WVD and not only.
This script never delete Resource group, NSG resource or the VNET associated.
## Scope
If you try to delete a VM from the Azure portal you're just deleting the vm and not all the associated resources like disks, Network interface, boot diagnostic storage ecc. Thats mean that you have a lot of orphaned resources that you still pay. This script is born to help us to delete completly the VM and all the resources. You can also delete a set of VM that have the same name with a number like example-1 example-2 ecc. You can find this type of configuration on the WVD.
## Configure
For local powershell you can download DeleteVmComplete.ps1 and use it on your computer
For Azure side with an automation account you must download Automation-DeleteAzureVm.ps1 and import it
You can download
## Requirements
### For local powershell
You must have Az module installed, you find here how to do it: https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.1.0
Once installed you must first login into your Azure account and on the correct Subscription.
Connect-AzAccount # Login with azure credential
Select-AzSubscription # Select the correct subscription.
### For Azure automation runbook
You must create a new automation account. After that you must import this modules from modules gallery:
Az.Accounts
Az.Compute
Az.Profile
Az.Tags
Az.Network
Az.resource
Az.Storage

## How to use
### For local powershell
Start the script:
Single Vm (0) or Pooled VM (1)?: You can select 0 for single VM delete and 1 for a pooled scenario.
If you select Single VM the only thing that you have to specify is the VM name.
If you select Pooled you have to specify the prefix the to value and the from value. If you want to delete a pool from example-1 to example-4 you must delete: example-1,example-2,example-3 and example-4 the the values will be prefix:example from 1 to 5(The to value will be exluded)
### For Azure automation runbook
You must set the parameters when you start the script:

VMNAME -> Mandatory only if you use the SINGLEORPOOLED parameter to Single. If you set it on pooled you can ignore it.
SINGLEORPOOLED-> Mandatory and you set Single if you want to delete a single vm or you set it on Pooled if you want to delete a vm pool
PREFIX -> Mandatory only if SINGLEORPOOLED is set to POOLED. This is the prefix name of the VM. EX: example-1 the prefix is example
FROM -> Mandatory only if SINGLEORPOOLED is set to POOLED. This is the first vm where to start: EX: 1 if i want to start with example-1
TO(Excluded) -> Mandatory only if SINGLEORPOOLED is set to POOLED. This is the last vm that the script delete: EX: If i want to finish with example-5 i will set it on 6. This value is exluded.

