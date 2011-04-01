connect = require("connect")

cookieParser = connect.cookieParser()

exports.getCookies = (req) ->
	if not req.cookies? then cookieParser req, null, ->
	return req.cookies

exports.getCookie = (req, cookie) ->
	return getCookies(req)[cookie]

