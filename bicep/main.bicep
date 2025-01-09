@description('Name of the AKS cluster')
param aksClusterName string = 'your name'

@description('Location of the AKS cluster')
param location string = resourceGroup().location

@description('Number of nodes in the cluster')
param nodeCount int = 10

@description('Size of VMs in the node pool')
param vmSize string = 'Standard_D2s_v3' or any

@description('OS disk size in GB')
param osDiskSizeGB int = 30

@description('Kubernetes version to deploy')
param kubernetesVersion string = '1.29.2'

@description('Administrator username for AKS node access')
param adminUsername string = 'azureuser'

@secure()
@description('Admin password for AKS node access')
param adminPassword string

@description('ID of the existing Virtual Network')
param vnetName string =  // Use your preferred VNet name

@description('Name of the existing Subnet in the Virtual Network')
param subnetName string =  // Use your preferred subnet name

// Variables
var subnetId = '${vnetName}/subnets/default'
var nodePoolName = 'nodepool1'

// Reference Existing VNet and Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}
 
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: subnetName
}
// Create a Managed Identity for the AKS Cluster
resource aksClusterIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${aksClusterName}-identity'
  location: location
}

// Create AKS Clusters
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-01-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksClusterIdentity.id}': {}
    }
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: aksClusterName
    agentPoolProfiles: [
      {
        name: nodePoolName
        count: nodeCount
        vmSize: vmSize
        vnetSubnetID: subnet.id
        osType: 'Linux'
        mode: 'System'
        osDiskSizeGB: osDiskSizeGB
      }
    ]

    // linuxProfile: {
      // adminUsername: adminUsername
      // adminPassword: adminPassword
    // } 

    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'Standard'
      outboundType: 'UserDefinedRouting'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: // Your private dns zone
      enablePrivateClusterPublicFQDN: false
    }
  }
}
