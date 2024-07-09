param storageNamePrefix string = 'DEV'
param location string = resourceGroup().location
param skuName string = 'Premium_LRS'
param storageKind string = 'FileStorage'

var storageName = '${toLower(storageNamePrefix)}${uniqueString(resourceGroup().id)}'

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
              mountPath: '/cfg20'
              name: 'emby-storage'
              readOnly: false
            }
          ]
          volume: [
            {
              name: 'emby-storage'
              azureFile: {
                shareName: 'nfsfileshare'
                storageAccountName: storageName
                storageAccountKey: storageAccount.outputs.
              }
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
  }
}

// storage for containers
module storageAccount 'br/public:avm/res/storage/storage-account:0.9.1' = {
  name: 'storageAccountDeployment'
  params: {
    // Required parameters
    name: storageName
    // Non-required parameters
    kind: storageKind
    location: location
    skuName: skuName
    fileServices: {
      shares: [
        {
          enabledProtocols: 'NFS'
          name: 'nfsfileshare'
        }
      ]
    }
  }
}

