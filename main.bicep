targetScope = 'resourceGroup'

param projPrefix string = 'ddf2'

var location = 'germanywestcentral'
var rgName = 'bicep-dev-1'
var storageSku = 'Standard_LRS'
var storageKind = 'StorageV2'

var saAccNameAppdata = '${projPrefix}saappdata4908'
var saAccNameMedia = '${projPrefix}samedia4286'
var saAccKeyAppdata = listkeys(resourceId('Microsoft.Storage/storageAccounts', saAccNameAppdata), '2019-06-01').keys[0].value
var saAccKeyMedia = listkeys(resourceId('Microsoft.Storage/storageAccounts', saAccNameMedia), '2019-06-01').keys[0].value


// foundational resources

resource resourceGroupName 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: rgName
  scope: subscription(rgName)
}

// network resources
module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.8' = {
  name: '${projPrefix}-virtualNetworkDeployment'
  scope: resourceGroup(resourceGroupName.name)
  params: {
    // Required parameters
    name: '${projPrefix}-vnet'
    addressPrefixes: [
      '10.10.0.0/16'
    ]
    location: location
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.10.0.0/24'
      }
      {
        name: 'ContainerInstanceSubnet'
        addressPrefix: '10.10.1.0/24'
        //nsg: vnetNsg.outputs.name
        delegations: [
          {
            name: 'delegate-ci'
            properties: {
              serviceName: 'Microsoft.ContainerInstance/containerGroups'
            }
          }
        ]
        networkSecurityGroup: {
          id: vnetNsg.outputs.resourceId
        }
      }
      {
        name: 'DefaultSubnet'
        addressPrefix: '10.10.2.0/24'
        networkSecurityGroup: {
          id: vnetNsg.outputs.resourceId
        }
      }
    ]
  }
}

module vnetNsg 'br/public:avm/res/network/network-security-group:0.4.0' = {
  name: '${projPrefix}-vnetNsgDeployment'
  scope: resourceGroup(resourceGroupName.name)
  params: {
    // Required parameters
    name: '${projPrefix}-vnetNsg'
    location: location
    securityRules: [
      {
        name: 'DenyAllInBound'
        properties: {
          access: 'Deny'
          description: 'Deny all inbound traffic'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 4096
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          access: 'Deny'
          description: 'Deny all outbound traffic'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Outbound'
          priority: 4096
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.5.0' = {
  name: 'privateDnsZoneDeployment'
  params: {
    // Required parameters
    name: 'biceptest.local'
    // Non-required parameters
    location: 'global'
  }
}

// storage for containers
module storageAccountAppdata 'br/public:avm/res/storage/storage-account:0.11.1' = {
  name: 'storageAccount-Appdata'
  scope: resourceGroup(resourceGroupName.name)
  params: {
    // Required parameters
    name: saAccNameAppdata
    location: location
    // Non-required parameters
    skuName: storageSku
    kind: storageKind
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          privateDnsZone.outputs.resourceId
        ]
        service: 'file'
        subnetResourceId: virtualNetwork.outputs.subnetResourceIds[2]
      }
    ]
    fileServices: {
      shares: [
        {
          name: 'emby-appdata'
          enabledProtocols: 'SMB'
          accessTier: 'Cool'
          shareQuota: 5
        }
        {
          name: 'emby-media'
          enabledProtocols: 'SMB'
          accessTier: 'Cool'
          shareQuota: 100
        }
        {
          name: 'plex-appdata'
          enabledProtocols: 'SMB'
          accessTier: 'Cool'
          shareQuota: 5
        }
        {
          name: 'plex-media'
          enabledProtocols: 'SMB'
          accessTier: 'Cool'
          shareQuota: 100
        }
      ]
      allowsharedaccesskey: false
      shareSoftDeleteEnabled: false
      largeFileSharesState: 'Enabled'

    }
  }
}

module storageAccountMedia 'br/public:avm/res/storage/storage-account:0.11.1' = {
  name: 'storageAccount-media'
  scope: resourceGroup(resourceGroupName.name)
  params: {
    // Required parameters
    name: saAccNameMedia
    location: location
    // Non-required parameters
    skuName: storageSku
    kind: storageKind
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          privateDnsZone.outputs.resourceId
        ]
        service: 'file'
        subnetResourceId: virtualNetwork.outputs.subnetResourceIds[2]
      }
    ]
    fileServices: {
      shares: [
        {
          name: 'emby-media'
          enabledProtocols: 'SMB'
          accessTier: 'Cool'
          shareQuota: 100
        }
        {
          name: 'plex-media'
          enabledProtocols: 'SMB'
          accessTier: 'Cool'
          shareQuota: 100
        }
      ]
      allowsharedaccesskey: false
      shareSoftDeleteEnabled: false
      largeFileSharesState: 'Enabled'
    }
  }
}

// container group
module containerGroup 'br/public:avm/res/container-instance/container-group:0.2.0' = {
  name: '${projPrefix}-containerGroupDeployment'
  scope: resourceGroup('bicep-dev-1')
  params: {
    // Required parameters
    name: '${projPrefix}-ci'
    ipAddressType: 'Private'
    subnetId: virtualNetwork.outputs.subnetResourceIds[1]
    autoGeneratedDomainNameLabelScope: 'SubscriptionReuse'
    containers: [
      {
        name: 'emby-server-v1'
        properties: {
          command: []
          environmentVariables: [
          ]
          image: 'linuxserver/emby:beta'
          ports: [
            {
              port: 8096
              protocol: 'Tcp'
            }
            {
              port: 8920
              protocol: 'Tcp'
            }
          ]
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 2
            }
          }
          volumeMounts: [
            {
              mountPath: '/config'
              name: 'emby-appdata'
              readOnly: false
            }
            {
              mountPath: '/media'
              name: 'emby-media'
              readOnly: true
            }
          ]
          }
        }
        {
          name: 'plex-server-v1'
          properties: {
            command: []
            environmentVariables: [
            ]
            image: 'linuxserver/plex'
            ports: [
              {
                port: 8324
                protocol: 'Tcp'
              }
              {
                port: 32400
                protocol: 'Tcp'
              }
            ]
            resources: {
              requests: {
                cpu: 2
                memoryInGB: 2
              }
            }
            volumeMounts: [
              {
                mountPath: '/config'
                name: 'plex-appdata'
                readOnly: false
              }
              {
                mountPath: '/media'
                name: 'plex-media'
                readOnly: true
              }
            ]
            }
          }
        
        ]
    ipAddressPorts: [
      {
        port: 8096
        protocol: 'Tcp'
      }
      {
        port: 8920
        protocol: 'Tcp'
      }
      {
        port: 8324
        protocol: 'Tcp'
      }
      {
        port: 32400
        protocol: 'Tcp'
      }
    ]
    // Non-required parameters
    location: location
    volumes: [
      {
        name: 'emby-appdata'
        azureFile: {
          shareName: 'emby-appdata'
          storageAccountName: saAccNameAppdata
          storageAccountKey: saAccKeyAppdata
        }
      }
      {
        name: 'emby-media'
        azureFile: {
          shareName: 'emby-media'
          storageAccountName: saAccNameMedia
          storageAccountKey: saAccKeyMedia
        }
      }
      {
        name: 'plex-appdata'
        azureFile: {
          shareName: 'plex-appdata'
          storageAccountName: saAccNameAppdata
          storageAccountKey: saAccKeyAppdata
        }
      }
      {
        name: 'plex-media'
        azureFile: {
          shareName: 'plex-media'
          storageAccountName: saAccNameMedia
          storageAccountKey: saAccKeyMedia
        }
      }
    ]
  }
}
