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

hubot_url = HUBOT_URL || HEROKU_URL || "http://#{require("os").hostname()}"
hubot_url = hubot_url[..-2] if hubot_url[hubot_url.length - 1] == "/"
client = new OAuth2(
  GOOGLE_API_CLIENT_ID,
  GOOGLE_API_CLIENT_SECRET,
  "#{hubot_url}/auth/googleapi/callback"
)
google.options(auth: client)

getCredential = (robot, callback)->
  credential = robot.brain.get("credential")
  unless credential
    return callback(new Error("Needs authorization. Authorize at #{hubot_url}/auth/googleapi"))

  client.setCredentials?(
    access_token: credential.access_token,
    refresh_token: credential.refresh_token
  )

  if Date.now() > credential.expiry_date
    client.refreshAccessToken (err, credential)->
      return callback(err) if err
      robot.brain.set "credential", credential
      callback(null, credential)
  else
    callback(null, credential)

module.exports = (robot)->
  robot.router.get "/auth/googleapi", (req, res)->
    res.redirect client.generateAuthUrl(
      access_type: "offline",
      # undocumented but necessary for getting a refresh_token
      approval_prompt: "force",
      scope: GOOGLE_API_SCOPES.split(",").map (e)->
        "https://www.googleapis.com/auth/#{e}"
    )

  robot.router.get "/auth/googleapi/callback", (req, res)->
    client.getToken req.query.code, (err, credential)->
      return res.send(err.message) if err
      robot.brain.set "credential", credential
      res.send("Authorization has succeeded!")

  robot.on "googleapi:request", ({service, version, endpoint, params, callback})->
    version = "v#{version}" if version[0] != "v"
    getCredential robot, (err, credential)->
      client = google[service](version)
      endpoint.split(".").reduce(((a, e)-> a[e]), client)(params, callback)
