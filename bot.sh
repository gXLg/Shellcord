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

    if [ "$cmd" == "sh!crash" ]
    then
      payload '{}'
    elif [ "$cmd" == "sh!hi" ]
    then
      message="<@$author>, hello!"
      post channels/$channel/messages '{"content":"'"$message"'"}' > /dev/null
    elif [ "$cmd" == "sh!status" ]
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
    elif [ "$cmd" == "sh!joke" ]
    then
      joke="$(curl -s https://v2.jokeapi.dev/joke/Programming)"
      if [ "$(echo $joke | jq -r .type)" == "single" ]
      then
        content="$(echo $joke | jq -r .joke)"
        content="$(raw $content)"
        post channels/$channel/messages '{"content":"'"$content"'"}' > /dev/null
      else
        setup="$(echo $joke | jq -r .setup)"
        setup="$(raw $setup)"
        delivery="$(echo $joke | jq -r .delivery)"
        delivery="$(raw $delivery)"
        post channels/$channel/messages '{"content":"'"$setup"'\n||'"$delivery"'||"}' > /dev/null
      fi
    fi
  fi
done
