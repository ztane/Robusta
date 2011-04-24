root       = exports ? this
robusta    = require 'robusta'
expose     = robusta.controller.expose
model      = require './model'

class SubController extends robusta.controller.Controller
        constructor: ->
                @init()

        index: expose (req, res) ->
                res.render("Hello world from SubController. Monday in" +
                    " Traditional Chinese is " +
                    res.translator.gettext "Monday")

        subview: expose (req, res) ->
                res.render "Hello world from SubController subview"

class TestController extends robusta.controller.Controller
        constructor: ->
                @init()

        subcontroller: new SubController()

        index: expose("base") (req, res) ->
                person = new model.Person { title: "Foobar Baz" }
                person.save()

                counts = ({ number: i } for i in [0..10]) 
                res.render counts: counts

        json: expose("json") (req, res, parts) ->
                res.render { "description": "A view rendering json" }

        fblogincheck: expose (req, res) ->
                if req.fb_session?
                        res.render "You have logged in to facebook"
                else
                        res.render "You have not logged in to facebook"

root.TestController = new TestController()
