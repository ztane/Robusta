util = require "robusta/lib/robusta/util"
fs   = require "fs"
path = require "path"

notTranslated = new util.HashMap()
translators   = new util.HashMap()
catalogs      = new util.HashMap()

# locale aliases go in here
aliases       = new util.HashMap()

# this always exists
aliases.put('en', 'en')

catalogDir    = ''

normalizeLanguage = (language) ->
    language = language.replace /[-.\/]/g, '_'
    parts = /^([a-z0-9]+)(?:_(.*))/i.exec(language)
    if parts[1]?
        language = parts[1].toLowerCase()
        if parts[2]
            language += "_" + parts[2].toUpperCase()

    return language

class Translator
    constructor: (catalog) ->
        @messages = new util.HashMap(catalog.catalog)
        @info = catalog.info
        @getPluralForm = Function("n", "var nplurals, plural; " +
            @info['plural-forms'] + "; return plural;")

    gettext: (msg) ->
        t = @messages.get(msg)
        if typeof(t) == 'string'
            return t

        if t and t.length?
            return t[0]

        return null

    ngettext: (msg, msgplural, n) ->
        t = @messages.get(msg)
        if typeof(t) == 'string'
            return t

        if t and t.length?
            form = @getPluralForm(n)
            return t[form]

        return null

getCatalogPath = (language) ->
    path.resolve catalogDir, language

# resolve recursively if a language exists...
getAlias = (original) ->
    if aliases.hasKey(original)
        return aliases.get(original)

    language = normalizeLanguage(original)
    if aliases.hasKey(language)
        alias = aliases.get(language)
        aliases.put(original, alias)
        return alias

    if path.existsSync getCatalogPath language
        aliases.put(original, language)
        aliases.put(language, language)
        return language

    if language.indexOf('_') != -1
        alias = getAlias(language.split('_')[0])
        if alias
            aliases.put(language, alias)
            aliases.put(original, alias)
            return alias

        notTranslated.put(original)
        notTranslated.put(language)

    return null

exports.DummyTranslator = DummyTranslator =
    gettext: (msg) ->
        msg

    ngettext: (msg, msgPlural, n) ->
        n == 1 and msg or msgPlural

    pgettext: (context, msg) ->
        msg

    pngettext: (context, msg, msgPlural, n) ->
        ngettext(msg, msgPlural, n)

createTranslator = (language) ->
    if language == 'en'
        return DummyTranslator

    catalogData = JSON.parse fs.readFileSync getCatalogPath language
    new Translator catalogData

getTranslator = (language) ->
    lang = getAlias language
    if not lang?
        return null

    if translators.hasKey lang
        return translators.get lang

    t = createTranslator lang
    translators.put lang, t
    return t

exports.setCatalogDirectory = (path) ->
    catalogDir = path

class FallbackTranslator
    constructor: (languages) ->
        @translators = []
        for i in languages
            translator = getTranslator i
            translator and @translators.push translator

    gettext: (msg) ->
        for i in @translators
            m = i.gettext(msg)
            return m if m?

        msg

    ngettext: (msg, msgPlural, n) ->
        for i in @translators
            m = i.ngettext msg, msgPlural, n
            return m if m?

        n == 1 and msg or msgPlural

    pgettext: (context, msg) ->
        cmsg = context + "\004" + msg
        t = @gettext cmsg

        if t == cmsg
            return msg

        t

    pngettext: (context, msg, msgPlural, n) ->
        cmsg = context + "\004" + msg
        t = @ngettext msg, msgPlural, n
        if t == cmsg
            return msg

        t

exports.createFallbackTranslator = (languages) ->
    new FallbackTranslator(languages)
