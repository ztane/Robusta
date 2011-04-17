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

        subcontroller: new SubController()

        index: expose (req, res) ->
                res.send "Hello world"
                person = new model.Person { title: "Foobar Baz" }
                person.save()

        foo: expose (req, res, parts) ->
                res.send("Another method with the remaining URI components " + parts)

        fb: expose (req, res) ->
                if req.fb_session?
                        res.send("You have logged in to facebook")
                else
                        res.send("You have not logged in to facebook")

root.TestController = new TestController()

context = createContext(translator)
context.name = 'Fred'
compiled = dust.compile """{#gettext}Hello  {~lb}  {~rb}  {name}  !  {/gettext} {#ngettext} asdfasdf  asdf asdf sdf {name} {:else}sdfasdasdfadf{/ngettext}""", "intro";
dust.loadSource compiled
dust.render "intro", context, (err, out) ->
    console.log out
dust.render "intro", context, (err, out) ->
    console.log out




