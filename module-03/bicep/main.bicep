@description('Web app name.')
@minLength(2)
param webAppName string = 'webApp-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The SKU of App Service Plan.')
param sku string = 'F1'

@description('The Runtime stack of current web app')
param linuxFxVersion string = 'DOTNETCORE|8.0'

var appServicePlanPortalName = 'AppServicePlan-${webAppName}'

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanPortalName
  location: location
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource http4xxAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'metricAlert-${webAppName}'
  location: 'global'
  properties: {
    autoMitigate: true
    criteria: {
      allOf: [
        {
          name: 'Http4xxThreshold'
          metricName: 'Http4xx'
          metricNamespace: 'Microsoft.Web/sites'
          timeAggregation: 'Total'
          operator: 'GreaterThan'
          threshold: 20
          criterionType: 'StaticThresholdCriterion'
          skipMetricValidation: false
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    description: 'Fires when 4xx spikes'
    enabled: true
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    severity: 2
    scopes: [
      webApp.id
    ]
    targetResourceType: 'Microsoft.Web/sites'
    targetResourceRegion: location
  }
}

output webAppName string = webApp.name
// output alertResourceId string = http4xxAlert.id
