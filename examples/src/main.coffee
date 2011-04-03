root       = exports ? this
robusta    = require 'robusta'
expose     = robusta.controller.expose
model      = require './model'

class SubController extends robusta.controller.Controller
        constructor: ->
                @init()

        index: expose (req, res) ->
                res.send("Hello world from SubController")

class TestController extends robusta.controller.Controller
        constructor: ->
                @init()

        index: expose (req, res) ->
                res.send "Hello world"
                person = new model.Person { title: "Foobar Baz" }
                person.save()

        foo: expose (req, res, parts) ->
                res.send("Another method with the remaining URI components " + parts)

        subcontroller: new SubController()

root.TestController = new TestController()
