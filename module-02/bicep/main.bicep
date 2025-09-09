
//Parameters
@description('The name of the virtual machine.')
param vmName string

@description('The location for the virtual machine.')
param location string = resourceGroup().location

@description('The size of the virtual machine.')
param vmSize string

@description('The admin username for the virtual machine.')
param adminUsername string

@description('The admin password for the virtual machine.')
@secure()
param adminPassword string

@description('The name of the virtual network.')
param vnetName string

@description('The name of the subnet.')
param subnetName string

@description('Name of the Storage Account. It must be unique and between 3 and 24 characters in length and can contain only lowercase letters and numbers.')
@minLength(3)
@maxLength(24)
param storageAccountName string = toLower('sa${uniqueString(resourceGroup().id)}')

// Variables
var nicName = '${vmName}-nic'
var publicIpName = '${vmName}-pip'

// Resources

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

// Public IP
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: publicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '22.04-LTS'
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

// Outputs
output vmId string = vm.id
output publicIpAddress string = publicIp.properties.ipAddress
