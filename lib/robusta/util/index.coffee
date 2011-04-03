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

merge = require './merge'

exports.extend = merge.extend
exports.isArray = merge.isArray
exports.isFunction = merge.isFunction
exports.isPlainObject = merge.isPlainObject
exports.deepCopy = merge.deepCopy
exports.shallowCopy = merge.shallowCopy
exports.getType = merge.getType

readConfig = (name, callback, herePointer) ->
    fs.readFile name, 'UTF-8', (err, data) ->
        if data
            data = JSON.parse data
            if data.extends?
                newCb = (err, baseData) ->
                    if baseData?
                       merge.extend(true, baseData, data)

                    callback(err, baseData)

                readConfig data.extends, newCb, herePointer
                return

            data.here = herePointer

        callback(err, data)

root.readConfig = (name, callback) ->
    here = path.dirname(path.resolve(name))
    readConfig(name, callback, here)

