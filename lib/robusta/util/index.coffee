root = exports ? this

fs   = require 'fs'
path = require 'path'

root.getFactoryFunction = (name, here) ->
	loc = name.indexOf ':'
	if loc == -1
		throw new Error "No : in factory function parameter " + name

	module = name.substr 0, loc
	func = name.substr loc + 1

	try
		mod = require module
	catch e
		if here?
			newpath = path.resolve(here, module)
			mod = require newpath
		else
			throw e

	resolved = mod
	for i in func.split '.'
		resolved = resolved[i]
		if not resolved?
			throw new Error "Component " + i + " not defined when resolving " + name

	return resolved

root.readConfig = (name, callback) ->
    fs.readFile name, 'UTF-8', (err, data) ->
        if data
            data = JSON.parse(data)
            data.here = path.dirname(path.resolve(name))

        callback(err, data)
