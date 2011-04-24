util      = require "robusta/lib/robusta/util"
fs        = require "fs"
path      = require "path"
functools = require "functools"

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
    if parts and parts[1]?
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

        if Array.isArray(t)
            form = +@getPluralForm(n)
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

        @_createClosures()

    _createClosures: () ->
        # create detachable closures
        @gettext = (msg) => @_gettext(msg)
        @ngettext = (msg, msgPlural, n) => @_ngettext(msg, msgPlural, n)
        @pgettext = (c, msg) => @_pgettext(c, msg)
        @npgettext = (c, msg, msgPlural, n) => @_npgettext(c, msg, msgPlural, n)

    _gettext: (msg) ->
        for i in @translators
            m = i.gettext(msg)
            return m if m?

        msg

    _ngettext: (msg, msgPlural, n) ->
        for i in @translators
            m = i.ngettext msg, msgPlural, n
            return m if m?

        n == 1 and msg or msgPlural

    _pgettext: (context, msg) ->
        cmsg = context + "\004" + msg
        t = @gettext cmsg

        if t == cmsg
            return msg

        t

    _npgettext: (context, msg, msgPlural, n) ->
        cmsg = context + "\004" + msg
        t = @ngettext msg, msgPlural, n
        if t == cmsg
            return msg

        t

# matches a value with optional quality
qualityRe = /^([^;]*)(;q=([0-9.]+))?/

# match ll_cc case insensitively
isoCodeMatch = /^([a-z][a-z])_([a-z][a-z])$/

parseAcceptLanguage = (req) ->
    # give the default language as en, for now...
    acceptLanguage = req.header 'Accept-Language', 'en'

    # remove spaces and replace dash with underscore
    acceptLanguage = acceptLanguage.replace(/\s+/g, '').replace(/-/g, '_')

    parts = acceptLanguage.split /,/
    langs = functools.map(((el, idx) ->
        q = 1
        groups = qualityRe.exec el
        if groups.length >= 4
            q = +groups[3]

        lang = groups[1]
        groups = /^([a-z][a-z])_([a-z][a-z])$/.exec lang
        if groups? and groups.length
            lang = groups[1] + "_" + groups[2].toUpperCase()

        return {
            lang: lang,
            idx: idx,
            q: q
        }),
        parts
    )

    # sort by quality DESC, idx ASC
    langs.sort (a, b) ->
        b.q - a.q or a.idx - b.idx;

    (el.lang for el in langs)

exports.getAcceptedLanguages = (req) ->
    if not req.parsedAcceptedLanguages?
        req.parsedAcceptedLanguages = parseAcceptLanguage(req)

    return req.parsedAcceptedLanguages

exports.createFallbackTranslator = (languages) ->
    new FallbackTranslator(languages)
