using './main.bicep'

param adminUsername = 'azureuser' // This should be secured using Azure Key Vault or similar methods in production
param adminPassword = 'P@ssw0rd1234!' // This should be secured using Azure Key Vault or similar methods in production

param vmName = 'module-02-vm'
param vmSize = 'Standard_B2s'
param vnetName = 'lab-vnet'
param subnetName = 'module-02-subnet'
