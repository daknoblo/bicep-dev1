param storageNamePrefix string = 'DEV'
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
    name: 'bicep-ci-deployment'
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
              name: 'emby-config'
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
        name: 'emby-config'
        azureFile: {
          shareName: 'emby-config'
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
    // Non-required parameters
    kind: storageKind
    allowBlobPublicAccess: true
    location: location
    skuName: skuName
    
    fileServices: {
      shares: [
        {
          name: 'emby-config'
          enabledProtocols: 'SMB'
          // accessTier: 'Cool'
          shareQuota: 1
        }
        {
          name: 'emby-media'
          enabledProtocols: 'SMB'
          // accessTier: 'Cool'
          shareQuota: 5
        }
      ]
      allowsharedaccesskey: true
      largeFileSharesState: 'Disabled'
    }
  }
}

