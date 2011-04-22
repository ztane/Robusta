root = exports ? this

require 'move'
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

        util.getFactoryFunction @config.rootController, @config.here

    configureMongoose: ->
        mongoose = require 'mongoose'
        if not @config.mongoose.modelRoot?
            throw new Error("No mongoose.modelRoot specified in config")

        if not @config.mongoose.connectionUri?
            throw new Error("No mongoose.connectionUri specified in config")

        db = mongoose.createConnection @config.mongoose.connectionUri
        modelRoot = util.getFactoryFunction @config.mongoose.modelRoot, @config.here
        modelRoot(db)

    getTemplateDirectory: ->
        @getGlobalPath(@config.templating.templateDir or "templates")

    configureTemplating: ->
        templates = require 'robusta/templates'
        templates.setTemplateDirectory @getTemplateDirectory()

    configureDispatch: ->
        root = @getRootController()
        @app.all /\/(.*)/, (req, res, next) ->
            controller.dispatch(req, res, root, next)

    configureFacebook: () ->
        connect_facebook = require 'connect_facebook'

        if not @config.facebook.appId?
            throw new Error "No facebook.appId specified in config"

        if not @config.facebook.appSecret?
            throw new Error "No facebook.appSecret specified in config"

        @app.use connect_facebook @config.facebook.appId, @config.facebook.appSecret

    configureI18N: () ->
        i18n = require 'robusta/lib/robusta/i18n'

        if @config.i18n and @config.i18n.enabled
            if not @config.i18n.catalogDir?
                throw new Error "No i18n.catalogDir specified in config"

            i18n.setCatalogDirectory path.resolve @config.here, @config.i18n.catalogDir
            @app.createTranslator = (languages) ->
               i18n.createFallbackTranslator(languages)
        else
            @app.createTranslator = () ->
               i19n.DummyTranslator


    createServer: (success) ->
        @app = express.createServer()
        @app.use express.bodyParser()
        @app.use express.methodOverride()
        if @config.staticDir?
            if @config.coffeeDir?
                @configureCoffeeCompilation()

            @configureStatic()

        if @config.mongoose and @config.mongoose.enabled
            @configureMongoose()

        if @config.facebook and @config.facebook.enabled
            @configureFacebook()

        if @config.templating and @config.templating.enabled
            @configureTemplating()

        @configureI18N()

        @configureDispatch()
        success(@app)

root.ServerFactory = ServerFactory
