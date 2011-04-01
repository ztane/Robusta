errorShield = (func) ->
	(req) ->
		try
			func.apply(this, arguments)
		catch error
			req._expressNext(error)

expose = (template = null, opts = {}) ->
	if (typeof template) is 'function'
		template.exposed =
			template: null
			opts: {}
		return template

	return (func) ->
		func.exposed =
			template: template
			opts: opts

class Controller
	constructor: ->
		@init()

	init: ->
		@exposed = {}
		meths = []
		`for (meth in this) { meths.push(meth); }`

		for meth in meths
			if this[meth].exposed?
				@exposed[meth] = this[meth].exposed

	_callViewMethod: (meth, req, res, comps) ->
		req.components = comps
		req._controllerSelf = this
		res._exposed = this[meth].exposed
		comps = comps.slice()
		comps.unshift req, res

		console.log this
		thisMeth = () =>
			this[meth].apply(this, arguments)

		(errorShield thisMeth).apply null, comps
		return

	_dispatch: (req, res, comps) ->
		if not comps.length
			part = 'index'
		else
			part = comps[0]
		if part == ''
			part = 'index'

		newComps = comps[1 ... comps.length]

		if part[0] != '_' and this[part]? and this[part].exposed?
			meth = this[part]
			if (typeof meth) is 'function'
				@_callViewMethod part, req, res, newComps
				return

			# it is a controller
			meth._dispatch req, res, newComps
			return

		if this['_default']? and this['_default'].exposed?
			@_callViewMethod part, req, res, comps
			return

		if this['_lookup']? and this['_lookup'].exposed?
			@_lookup(req, res, comps)
			return

		req._expressNext()

dispatch = (req, res, root, next) ->
	path = req.params[0]
	comps = path.split "/"
	req._expressNext = next
	root._dispatch req, res, comps

NotFound = (msg) ->
	@name = 'NotFound';
	Error.call this, msg
	Error.captureStackTrace this, arguments.callee

NotFound.prototype.__proto__ = Error.prototype

exports.Controller  = Controller
exports.NotFound    = NotFound

exports.dispatch    = dispatch
exports.errorShield = errorShield
exports.expose      = expose
