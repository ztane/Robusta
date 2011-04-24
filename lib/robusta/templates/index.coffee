util = require '../util'
dust = require 'dust'
fs   = require 'fs'
path = require 'path'

dust.optimizers.format = (ctx, node) -> node

translationCache = new util.HashMap()
bodyCache        = new util.HashMap()

class I18NChunk
    constructor: (@onError) ->
        @textContents = []
        @render = []
        @inError = false
        @references = {}

    gotError: (error) ->
        @onError(error)
        @inError = true
        this

    write: (data) ->
        content = data.replace /[{}]/g, (match) ->
            if match == '{'
                '{~lb}'
            else
                '{~rb}'

        @textContents.push content
        @render.push (chunk, context) ->
            chunk.write(data)

        this

    map: (callback) ->
        @gotError("Map called within i18n chunk")

    end: (data) ->
        @gotError("End called within i18n chunk")

    tap: (callback) ->
        @gotError("Unable to tap i18n chunk")

    untap: () ->
        @gotError("Unable to untap i18n chunk")

    untap: () ->
        @gotError("Unable to render on i18n chunks")

    setError: (error) ->
        @gotError("Error within i18n chunk: " + error)

    reference: (elem, context, auto, filters) ->
        @textContents.push elem.text
        @render.push elem.func(auto, filters)
        @references[elem.name] = elem.func(auto, filters)

        this

    section: ()->
        @gotError("No sections allowed within i18n chunks")

    exists: ()->
        @gotError("No exist allowed within i18n chunk")

    notexists: () ->
        @gotError("No notexists allowed within i18n chunk")

    partial: () ->
        @gotError("No partials within i18n chunk")

    helper: () ->
        @gotError("No helpers allowed within i18n chunk")

    toString: () ->
        if not @string?
            @string = @textContents.join('')

        return @string

createGetFunc = (name) ->
    (auto, filters) ->
        (chk, ctx) -> chk.reference ctx.get(name), ctx, auto, filters

createGetPathFunc = (relative, comps) ->
    (auto, filters) ->
        (chk, ctx) -> chk.reference ctx.getPath(relative, comps), ctx, auto, filters

createWrite = (text) ->
    (chk, ctx) -> chk.write(text)

class I18NHelperContext
    get: (name) ->
        return {
             text: '{' + name + '}',
             name: name,
             func: createGetFunc(name)
        }

    getPath: (relative, comps) ->
        name = ''
        name = '.' if relative
        name = name + comps.join '/'
        return {
            text: '{' + name + '}',
            name: name,
            func: createGetPathFunc(relative, comps)
        }

currentId = 1
getBody = (body) ->
    if not body.cacheId?
        body.cacheId = currentId
        currentId += 1

    cached = bodyCache.get(body.cacheId)
    if cached == undefined
        chk = new I18NChunk((error) =>
            @gotError error
        )
        ctx = new I18NHelperContext()
        cached = body chk, ctx
        bodyCache.put(body.cacheId, cached)

    return cached

tagmatcher = ///
    ( [^{]+ )
|
    \{
        (?:
           ~ (lb|rb)
        |
           ([.]?[a-zA-Z_$][a-zA-Z0-9_$/]*)
        )
    \}
|m
    ( [{] )
///g

createTranslatedBody = (references, translated) ->
    bodyContent = []
    translated.replace tagmatcher, (all, plaintext, escapedbracket, reference, plainbracket) ->
        plaintext = '{' if escapedbracket == 'lb'
        plaintext = '}' if escapedbracket == 'rb'
        plaintext = plainbracket if plainbracket?

        if plaintext
            bodyContent.push plaintext
        else
            bodyContent.push reference: reference

    currentwrite = []
    ops = []
    for i in bodyContent
        if i.reference?
            if currentwrite.length
                ops.push createWrite currentwrite.join ''
                currentwrite = []

            ops.push references[i.reference]
        else
            currentwrite.push i

    if currentwrite.length
        ops.push createWrite currentwrite.join ''

    return ops

renderNew = (chunk, context, references, translated) ->
    cached = translationCache.get translated
    if cached == undefined
        cached = createTranslatedBody references, translated
        translationCache.put translated, cached

    for i in cached
        chunk = i(chunk, context)

    chunk

context_gettext = (translator, chunk, context, bodies, params) ->
    body = getBody(bodies.block)
    toGettext = body.toString()
    translated = translator.gettext(toGettext)
    if toGettext == translated
        chunk.render(bodies.block, context)
    else
        return renderNew(chunk, context, body, translated)

class GetNgettextNumberChunk
    constructor: () ->
        @text = ''

    reference: (data, ctx, filters) ->
        # TODO: warn about errors
        @text += data
        this

    write: (text) ->
        @text += text
        this

context_ngettext = (translator, chunk, context, bodies, params) ->
    number = params["n"]

    # reference the contents... the number is 0 if async,
    # TODO: warn in this case...
    if typeof(number) == 'function'
        chk = new GetNgettextNumberChunk()
        number(chk, context)
        number = +chk.text

    singular = getBody(bodies.block)
    plural = getBody(bodies['plural'])
    util.extend singular.references, plural.references

    translated = translator.ngettext(singular.toString(), plural.toString(), number)

    if translated == singular
        return chunk.render(bodies.block, context)
    else if translated == plural
        return chunk.render(bodies['plural'], context)
    else
        return renderNew(chunk, context, singular.references, translated)

createI18NContext = (translator, context) ->
    context = util.shallowCopy(context)

    context.gettext = (chunk, context, bodies, params) ->
        context_gettext(translator, chunk, context, bodies, params)

    context._ = context.gettext

    context.ngettext = (chunk, context, bodies, params) ->
        context_ngettext(translator, chunk, context, bodies, params)

    context._n = context.ngettext

    return context

templateDirectory = ''
setTemplateDirectory = (path) ->
    templateDirectory = path

dust.onLoad = (name, callback) ->
    tmpl = path.resolve(templateDirectory, name + ".dust")
    fs.readFile tmpl, 'UTF-8', callback

renderTemplate = (name, context, translator) ->
    if translator?
        context = createI18NContext translator, context

    dust.stream(name, context)

exports.createI18NContext = createI18NContext
exports.setTemplateDirectory = setTemplateDirectory
exports.renderTemplate = renderTemplate
