if [ "$token" == "" ]
then
  echo "You did not specify the token"
  exit 1
fi

if [ "$1" != "abobus" ]
then
  bash "$0" abobus && bash lib/end.sh
  exit
fi
source lib/import.sh

bot "$token"

if $debug; then echo "logged in, probably"; fi
while true
do
  receive
  if $(cat pipe/broken); then break; fi
  type="$(echo $event | jq -r .t)"
  if [ "$type" == "MESSAGE_CREATE" ]
  then
    content="$(echo $event | jq -r .d.content)"
    cmd="$(echo $content | cut -d ' ' -f 1)"
    author="$(echo $event | jq -r .d.author.id)"
    bot="$(echo $event | jq -r .d.author.bot)"
    msg="$(echo $event | jq -r .d.id)"
    channel="$(echo $event | jq -r .d.channel_id)"

    if [ "$cmd" == "sh!hi" ]
    then
      message="<@$author>, hello!"
      post channels/$channel/messages '{"content":"'"$message"'"}' > /dev/null
    fi
    if [ "$cmd" == "sh!close" ]
    then
      if [ "$author" == "557260090621558805" ]
      then
        put channels/$channel/messages/$msg/reactions/📴/@me
        break
      else
        post channels/$channel/messages '{"content":"Missing perms"}' > /dev/null
      fi
    fi
    if [ "$cmd" == "sh!status" ]
    then
      args="$(echo $content | cut -d ' ' -f 2-)"
      args="$(raw $args)"
      payload '{
        "op" : 3,
        "d" : {
          "status" : "online",
          "since" : 0,
          "afk" : false,
          "activities" : [{
            "name" : "'"$args"'",
            "type" : 0
          }]
        }
      }'
    fi
    if [ "$cmd" == "sh!voice" ]
    then
      payload '{
        "op" : 4,
        "d" : {
          "guild_id" : "886924058460028959",
          "channel_id" : "886924058460028963",
          "self_mute" : false,
          "self_deaf" : false
        }
      }'
    fi
    if [ "$cmd" == "sh!voice_x" ]
    then
      payload '{
        "op" : 4,
        "d" : {
          "guild_id" : "886924058460028959",
          "channel_id" : null,
          "self_mute" : false,
          "self_deaf" : false
        }
      }'
    fi
  fi
done
