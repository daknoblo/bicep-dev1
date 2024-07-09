
module containerGroup 'br/public:avm/res/container-instance/container-group:0.2.0' = {
  name: 'containerGroupDeployment'
  scope: resourceGroup('bicep-dev-1')
  params: {
    // Required parameters
    containers: [
      {
        name: 'az-aci-x-001'
        properties: {
          command: []
          environmentVariables: []
          image: 'mcr.microsoft.com/azuredocs/aci-helloworld'
          ports: [
            {
              port: 80
              protocol: 'Tcp'
            }
            {
              port: 443
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
        port: 80
        protocol: 'Tcp'
      }
      {
        port: 443
        protocol: 'Tcp'
      }
    ]
    name: 'cicgwaf001'
    // Non-required parameters
    location: '<location>'
    lock: {
      kind: 'CanNotDelete'
      name: 'myCustomLockName'
    }
    tags: {
      Environment: 'Non-Prod'
      'hidden-title': 'This is visible in the resource name'
      Role: 'DeploymentValidation'
    }
  }
}
