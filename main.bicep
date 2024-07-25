param storageNamePrefix string = 'sto'
param location string = resourceGroup().location

var storageName = '${toLower(storageNamePrefix)}${uniqueString(resourceGroup().id)}'
var storageAccKey = listkeys(resourceId('Microsoft.Storage/storageAccounts', storageName), '2019-06-01').keys[0].value

// deployment

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.8' = {
  name: 'virtualNetworkDeployment'
  scope: resourceGroup('bicep-dev-1')
  params: {
    // Required parameters
    name: 'vnet1'
    addressPrefixes: [
      '10.10.0.0/16'
    ]
    location: resourceGroup().location
    subnets: [
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.10.0.0/24'
      }
      {
        name: 'container-instance-subnet'
        addressPrefix: '10.10.1.0/24'
        delegations: [
          {
            name: 'delegate-ci'
            properties: {
              serviceName: 'Microsoft.ContainerInstance/containerGroups'
            }
          }
        ]
      }
    ]
  }
}

module containerGroup 'br/public:avm/res/container-instance/container-group:0.2.0' = {
  name: 'containerGroupDeployment'
  scope: resourceGroup('bicep-dev-1')
  params: {
    // Required parameters
    name: 'container-instance-1'
    ipAddressType: 'Private'
    subnetId: virtualNetwork.outputs.subnetResourceIds[1]
    containers: [
      {
        name: 'emby-server-v1'
        properties: {
          command: []
          environmentVariables: [
          ]
          image: 'linuxserver/emby:latest'
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
    ]
    // Non-required parameters
    location: location
    volumes: [
      {
        name: 'emby-appdata'
        azureFile: {
          shareName: 'emby-appdata'
          storageAccountName: storageName
          storageAccountKey: storageAccKey
        }
      }
      {
        name: 'emby-media'
        azureFile: {
          shareName: 'emby-media'
          storageAccountName: storageName
          storageAccountKey: storageAccKey
        }
      }
    ]
  }
}

// storage for containers
module storageAccount 'br/public:avm/res/storage/storage-account:0.11.0' = {
  name: 'storageAccountDeployment'
  params: {
    // Required parameters
    name: storageName
    location: location
    // Non-required parameters
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
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
      ]
      allowsharedaccesskey: true
      largeFileSharesState: 'Enabled'
      shareSoftDeleteEnabled: false
    }
  }
}

// asd
