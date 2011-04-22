root       = exports ? this
robusta    = require 'robusta'
expose     = robusta.controller.expose
model      = require './model'

class SubController extends robusta.controller.Controller
        constructor: ->
                @init()

        index: expose (req, res) ->
                res.render "Hello world from SubController"

class TestController extends robusta.controller.Controller
        constructor: ->
                @init()

        subcontroller: new SubController()

        index: expose("base") (req, res) ->
                person = new model.Person { title: "Foobar Baz" }
                person.save()
                res.render { }

        json: expose("json") (req, res, parts) ->
                res.render { "description": "A view rendering json" }

        fblogincheck: expose (req, res) ->
                if req.fb_session?
                        res.render "You have logged in to facebook"
                else
                        res.render "You have not logged in to facebook"

root.TestController = new TestController()
