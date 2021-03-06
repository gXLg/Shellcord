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
  "If the last, you may delete the file, but proceed with caution"
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

  sequence=null

  event=$(cat pipe/event)
  if [ "$event" == "end" ]
  then
    rm pipe/payload
    rm pipe/event
    $debug && echo "Unknown error on first connection"
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
    echo '{"op":1,"d":'$sequence'}' > pipe/payload
  done)&
  echo $! > pipe/loopid

  token="$1"
  intents="$2"
  if [ "$intents" == "" ]
  then
    echo '{"op":2,"d":{"token":"'$token'","properties":{"$os":"linux","$browser":"'"$client"'","$device":"calculator"}}}' > pipe/payload
  else
    echo '{"op":2,"d":{"token":"'$token'","intents":'$intents',"properties":{"$os":"linux","$browser":"'"$client"'","$device":"calculator"}}}' > pipe/payload
  fi
}

payload() {
  echo $1 > pipe/payload
}

receive() {
  event="$(cat pipe/event)"
  echo false > pipe/broken
  if [ "$event" == "end" ]
  then
    echo true > pipe/broken
  elif [ "$event" == "reconnect" ]
  then
    $debug && echo "Reconnecting..."
    kill $(cat pipe/loopid)
    rm pipe/loopid
    kill $(cat pipe/sleepid)
    rm pipe/sleepid
    echo end > pipe/payload

    python lib/wsio.py "wss://gateway.discord.gg/?v=6&encoding=json" pipe/payload pipe/event &

    event=$(cat pipe/event)
    if [ "$event" == "end" ]
    then
      rm pipe/payload
      rm pipe/event
      $debug && echo "Unknown error on first connection"
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
      echo '{"op":1,"d":'$sequence'}' > pipe/payload
    done)&
    echo $! > pipe/loopid

    payload '{
      "op": 6,
      "d": {
        "token": "'"$token"'",
        "session_id": "'"$session_id"'",
        "seq": '$sequence'
      }
    }'

    receive
  else

    if [ "$(echo $event | jq -r .s)" != null ]
    then
      sequence=$(echo $event | jq -r .s)
    elif [ ! "$sequence" ]
    then
      sequence=null
    fi
    $debug && echo "Event sequence: $sequence ($(echo $event | jq -r .t))"

    if [ "$(echo $event | jq -r .t)" == "READY" ]
    then
      session_id=$(echo $event | jq -r .d.session_id)
    elif [ "$(echo $event | jq -r .op)" == 7 ]
    then
      true
#      payload '{
#        "op": 6,
#        "d": {
#          "token": "'"$token"'",
#          "session_id": "'"$session_id"'",
#          "seq": '$sequence'
#        }
#      }'
    fi
  fi
}
