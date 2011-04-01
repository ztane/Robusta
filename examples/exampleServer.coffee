appConfig  = require "robusta/config/appConfig"
cookies    = require "robusta/cookies"
controller = require "robusta/controller"
expose     = controller.expose

config =
        coffeeDir: __dirname + '/client'
        publicDir: __dirname + '/data/public'

factory = new appConfig.ServerCreator config

app = factory.createServer()

class UserController extends controller.Controller
        constructor: ->
                @init()

        index: expose (req, res) ->
                res.send("Hello world")

        foo: expose (req, res) ->
                res.send("Another method")

class TestController extends controller.Controller
        constructor: ->
                @init()

        index: expose (req, res) ->
                res.send("Hello world")

        foo: expose (req, res, parts) ->
                res.send("Another method" + parts)

        users: new UserController()

root = new TestController()
console.log root.exposed

app.get /\/(.*)/, (req, res, next) ->
        controller.dispatch(req, res, root, next)

app.listen 8000
console.log "Server listening to http://localhost:8000"

