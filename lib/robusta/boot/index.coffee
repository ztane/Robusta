root = exports ? this

util = require 'robusta/lib/robusta/util'

root.initializeWithConfig = (config, success) ->
    factoryName = config.serverFactory ? 'robusta:config.ServerFactory'
    fact = util.getFactoryFunction(factoryName)
    factory = new fact config
    server = factory.createServer (app) ->
        success(config, app)

root.initializeWithConfigFile = (file, success) ->
    util.readConfig file, (err, data) ->
        throw err if err
        root.initializeWithConfig(data, success)
