param storageNamePrefix string = 'DEV'
param location string = resourceGroup().location
param skuName string = 'Premium_LRS'

var storageName = '${toLower(storageNamePrefix)}${uniqueString(resourceGroup().id)}'

module storageAccount 'br/public:avm/res/storage/storage-account:0.9.1' = {
  name: 'storageAccountDeployment'
  params: {
    // Required parameters
    name: storageName
    // Non-required parameters
    kind: 'BlockBlobStorage'
    location: location
    skuName: skuName
  }
}

output stgOutput string = storageName
