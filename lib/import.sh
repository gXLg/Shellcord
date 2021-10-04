client="Shellcord (https://github.com/gXLg/Shellcord, 1.0)"

raw() {
  local txt=$(echo $*|sed 's/"/\\\"/g')
  echo $txt
}

post() {
  curl -s -X "POST" \
  -H "Authorization: Bot ${token}" \
  -H "User-Agent: ${client}" \
  -H "Content-Type: application/json" \
  -d "$2" \
  "https://discordapp.com/api/$1"
}

get() {
  curl -s -X "GET" \
  -H "Authorization: Bot ${token}" \
  -H "User-Agent: ${client}" \
  -H "Content-Type: application/json" \
  "https://discordapp.com/api/$1"
}

delete() {
  curl -s -X "DELETE" \
  -H "Authorization: Bot ${token}" \
  -H "User-Agent: Shellcord ${client}" \
  -H "Content-Type: application/json" \
  "https://discordapp.com/api/$1"
}

put() {
  curl -s -X "PUT" \
  -H "Authorization: Bot ${token}" \
  -H "User-Agent: ${client}" \
  -H "Content-Type: application/json" \
  -d "" \
  "https://discordapp.com/api/$1"
}

bot() {
  trap "echo;echo Ctrl-C;exit" SIGINT

  if [ -p "pipe/payload" ] || [ -p "pipe/event" ]
  then
    echo -e "ERROR: Some of the websockets exist, that may be because "\
  "an instance is running already or the programm did not clean up the file\n"\
  "If the last, you may delete the file but proceed with caution"
    exit 1
  fi
  if [ -f "pipe/payload" ] || [ -f "pipe/event" ]
  then
    echo -e "ERROR: Some of the websockets exist as a file, clean the pipe directory"
    exit 1
  fi
  mkfifo pipe/payload
  mkfifo pipe/event
  python lib/wsio.py "wss://gateway.discord.gg/?v=6&encoding=json" pipe/payload pipe/event &

  event=$(cat pipe/event)
  if [ "$event" == "end" ]
  then
    rm pipe/payload
    rm pipe/event
    exit 1
  fi
  interval=$(echo $event | jq .d.heartbeat_interval )
  interval=$(echo "scale=2; $interval / 1000" | bc )

  (while true
  do
    sleep $interval &
    sleepid=$!
    echo $sleepid > pipe/sleepid
    wait $sleepid
    echo '{"op":1,"d":null}' > pipe/payload
  done)&
  echo $! > pipe/loopid

  if [ "$2" == "" ]
  then
    echo '{"op":2,"d":{"token":"'$1'","properties":{"$os":"linux","$browser":"'"${client}"'","$device":"calculator"}}}' > pipe/payload
  else
    echo '{"op":2,"d":{"token":"'$1'","intents":'$2',"properties":{"$os":"linux","$browser":"'"${client}"'","$device":"calculator"}}}' > pipe/payload
  fi
}

payload() {
  echo $1 > pipe/payload
}

receive() {
  event="$(cat pipe/event)"
  if [ "$event" == "end" ]
  then
    echo true > pipe/broken
  else
    echo false > pipe/broken
  fi
}
