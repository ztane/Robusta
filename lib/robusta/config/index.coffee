root = exports ? this

express    = require 'express'
path       = require 'path'
util       = require 'robusta/lib/robusta/util'
controller = require 'robusta/lib/robusta/controller'

class ServerFactory
    constructor: (@config) ->

    getGlobalPath: (orig) ->
        path.resolve @config.here, orig

    configureCoffeeCompilation: ->
        @app.use express.compiler src: @getGlobalPath(@config.coffeeDir), dest: @getGlobalPath(@config.publicDir), enable: ['coffeescript']

    configureStatic: ->
        @app.use express.static @getGlobalPath(@config.publicDir)

    getRootController: ->
        if not @config.rootController
            throw new Error("No rootController specified in config")

        util.getFactoryFunction(@config.rootController, @config.here)

    configureMongoose: ->
        mongoose = require 'mongoose'
        if not @config.mongoose.modelRoot?
            throw new Error("No mongoose.modelRoot specified in config")

        if not @config.mongoose.connectionUri?
            throw new Error("No mongoose.connectionUri specified in config")

        db = mongoose.createConnection @config.mongoose.connectionUri
        modelRoot = util.getFactoryFunction @config.mongoose.modelRoot, @config.here
        modelRoot(db)

    configureDispatch: ->
        root = @getRootController()
        @app.get /\/(.*)/, (req, res, next) ->
            controller.dispatch(req, res, root, next)

    createServer: (success) ->
        @app = express.createServer()
        @app.use express.bodyParser()
        @app.use express.methodOverride()
        if @config.staticDir?
            if @config.coffeeDir?
                @configureCoffeeCompilation()

            @configureStatic()

        if @config.mongoose? and @config.mongoose.enabled
            @configureMongoose()

        @configureDispatch()

        success(@app)

root.ServerFactory = ServerFactory

