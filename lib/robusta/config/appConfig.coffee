root = exports ? this

express = require('express')

class ServerCreator
    constructor: (@config) ->

    configureStatic: ->
        @app.use express.compiler(src: @config.coffeeDir, dest: @config.publicDir, enable: ['coffeescript'])
        @app.use express.static(@config.publicDir)

    createServer: ->
        @app = express.createServer()
        @app.use express.bodyParser()
        @app.use express.methodOverride()
        @configureStatic()
        return @app

root.ServerCreator = ServerCreator

