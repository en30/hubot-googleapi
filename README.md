hubot-googleapi
================

A hubot script for using google APIs

## Installation
Run

```sh
$ npm install hubot-googleapi --save
```

Add `hubot-googleapi` to `external-scripts.json`

## Required environment variables

Variable name               | Description             | Example
--------------------------- | ----------------------- | -----------------
`HEROKU_URL` or `HUBOT_URL` |                         | http://your-hubot.example.com
`GOOGLE_API_CLIENT_ID`      | CLIENT ID you created on Google Developers Console  |
`GOOGLE_API_CLIENT_SECRET`  | CLIENT SECRET you created on Google Developers Console |
`GOOGLE_API_SCOPES`         | CSV scope names you want to use | adsense.readonly,analytics.readonly

To get CLIENT ID and CLIENT SECRET,

1. Create a project at [API console](https://code.google.com/apis/console/).
2. Enable APIs you want to use at `API & auth > APIs`.
3. Go to `APIs & auth > Credentials`, and create new Client ID. AUTHORIZED REDIRECT URI should be `YOUR_HUBOT_URL/auth/googleapi/callback`.

## Usage

### Authorization
Authorize through OAuth2

```
en30> hubot googleapi auth
hubot> Authorize at http://your-hubot.example.com/auth/googleapi
```

### Event
`hubot-googleapi` listens on `googleapi:request` events, and you can use Google APIs by emitting them.

```coffee
# in your scripts
robot.emit "googleapi:request",
  service: "analytics"
  version: "v3"
  endpoint: "management.profiles.list"
  params:
    accountId: '~all'
    webPropertyId: '~all'
  callback: (err, data)->
    return console.log(err) if err
    console.log data.items.map((item)->
      "#{item.name} - #{item.websiteUrl}"
    ).join("\n")
```

`endpoint` corresponds to method names of [google/google-api-nodejs-client](https://github.com/google/google-api-nodejs-client).
