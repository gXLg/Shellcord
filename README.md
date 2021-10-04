# Shellcord
Lite discord bot library written in bash

Having almost no dependencies, it's the fastest way to test your Discord API knowledge

# Version
v1.0

No future updates in sight.

# Features
- [x] Websocket client
- [x] Simple interactions
- [x] Heartbeat automatisation and shutdown
- [x] Ctrl-C capturing
- [x] Login with intents
- [ ] ~~Voice gateways~~
- [ ] ~~v9 Gateway (will force gateway intents)~~
- [ ] ~~Sharding~~

# Using
The library is only able to handle messages.
No voice gateways (it can connect but not play anything).

To run start it like this from your command line:
```sh
token="..." bash bot.sh
```

You may edit anything after the `if $(cat pipe/broken); then break; fi` in bot.sh
