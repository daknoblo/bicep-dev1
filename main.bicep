param storageNamePrefix string = 'DEV'
param location string = resourceGroup().location
param skuName string = 'Standard_LRS'

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
          image: 'mcr.microsoft.com/azuredocs/aci-helloworld'
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


module storageAccount 'br/public:avm/res/storage/storage-account:0.9.1' = {
  name: 'storageAccountDeployment'
  params: {
    // Required parameters
    name: storageName
    // Non-required parameters
    kind: 'BlockBlobStorage'
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

