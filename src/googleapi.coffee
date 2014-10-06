# Description:
#   A hubot script for google APIs
#
# Dependencies:
#   "googleapis": "^1.0.14"
#
# Configuration:
#   HEROKU_URL or HUBOT_URL
#   GOOGLE_API_CLIENT_ID
#   GOOGLE_API_CLIENT_SECRET
#   GOOGLE_API_SCOPES
#
# Commands:
#   hubot googleapi auth - Returns authorization URL
#
# URLS:
#   /auth/googleapi
#   /auth/googleapi/callback
#
# Author:
#   en30

google = require("googleapis")
{OAuth2} = google.auth

{HUBOT_URL, HEROKU_URL,
GOOGLE_API_CLIENT_ID, GOOGLE_API_CLIENT_SECRET, GOOGLE_API_SCOPES} = process.env

HUBOT_URL = HUBOT_URL || HEROKU_URL || "http://#{require("os").hostname()}"
HUBOT_URL = HUBOT_URL[..-2] if HUBOT_URL[HUBOT_URL.length - 1] == "/"
AUTH_PATH = "/auth/googleapi"

client = new OAuth2(
  GOOGLE_API_CLIENT_ID,
  GOOGLE_API_CLIENT_SECRET,
  "#{HUBOT_URL}/auth/googleapi/callback"
)
google.options(auth: client)

updateCredential = (robot, callback)->
  credential = robot.brain.get("credential")
  unless credential
    return callback(new Error("Needs authorization. Authorize at #{HUBOT_URL}#{AUTH_PATH}"))

  client.setCredentials(
    access_token: credential.access_token,
    refresh_token: credential.refresh_token
  )

  if Date.now() > credential.expiry_date
    client.refreshAccessToken (err, credential)->
      return callback(err) if err
      robot.brain.set "credential", credential
      callback(null)
  else
    callback(null)

module.exports = (robot)->
  robot.respond /googleapi auth(orize)?$/, (msg)->
    msg.send "Authorize at #{HUBOT_URL}#{AUTH_PATH}"

  robot.router.get AUTH_PATH, (req, res)->
    res.redirect client.generateAuthUrl(
      access_type: "offline",
      # undocumented but necessary for getting a refresh_token
      approval_prompt: "force",
      scope: GOOGLE_API_SCOPES.split(",").map (e)->
        "https://www.googleapis.com/auth/#{e}"
    )

  robot.router.get "#{AUTH_PATH}/callback", (req, res)->
    client.getToken req.query.code, (err, credential)->
      return res.send(err.message) if err
      robot.brain.set "credential", credential
      res.send("Authorization has succeeded!")

  robot.on "googleapi:request", ({service, version, endpoint, params, callback})->
    version = "v#{version}" if version[0] != "v"
    updateCredential robot, (err)->
      return callback(err) if err
      serviceClient = google[service](version)
      endpoint.split(".").reduce(((a, e)-> a[e]), serviceClient)(params, callback)
