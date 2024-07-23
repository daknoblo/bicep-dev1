param storageNamePrefix string = 'sto'
param location string = resourceGroup().location
param skuName string = 'Premium_LRS'
param storageKind string = 'FileStorage'

var storageName = '${toLower(storageNamePrefix)}${uniqueString(resourceGroup().id)}'
var storageAccKey = listkeys(resourceId('Microsoft.Storage/storageAccounts', storageName), '2019-06-01').keys[0].value

// deployment
module containerGroup 'br/public:avm/res/container-instance/container-group:0.2.0' = {
  name: 'containerGroupDeployment'
  scope: resourceGroup('bicep-dev-1')
  params: {
    // Required parameters
    name: 'container-instance-1'
    containers: [
      {
        name: 'emby-server-v1'
        properties: {
          command: []
          environmentVariables: []
          image: 'linuxserver/emby:4.8.8'
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
              name: 'container-emby'
              readOnly: false
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
        name: 'container-emby'
        azureFile: {
          shareName: 'container-emby'
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
    // Non-required parameters
    kind: storageKind
    allowBlobPublicAccess: true
    location: location
    skuName: skuName
    
    fileServices: {
      shares: [
        {
          name: 'container-emby'
          enabledProtocols: 'SMB'
          // accessTier: 'Cool'
          shareQuota: 100
        }
      ]
      allowsharedaccesskey: true
      largeFileSharesState: 'Disabled'
    }
  }
}

