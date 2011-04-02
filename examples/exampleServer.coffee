robusta    = require 'robusta'
expose     = robusta.controller.expose

# An example config:
# serve public data from data/public subdirectory,
# and automatically compile coffeescripts from client
# subdirectory to be sent to client side
config =
        coffeeDir: __dirname + '/client'
        publicDir: __dirname + '/data/public'

class SubController extends robusta.controller.Controller
        constructor: ->
                @init()

        index: expose (req, res) ->
                res.send("Hello world from SubController")

class TestController extends robusta.controller.Controller
        constructor: ->
                @init()

        index: expose (req, res) ->
                res.send("Hello world")

        foo: expose (req, res, parts) ->
                res.send("Another method with the remaining URI components " + parts)

        subcontroller: new SubController()

root = new TestController()

factory = new robusta.config.ServerCreator config
app = factory.createServer()

app.get /\/(.*)/, (req, res, next) ->
        robusta.controller.dispatch(req, res, root, next)

app.listen 8000
console.log "Server listening to http://localhost:8000"

