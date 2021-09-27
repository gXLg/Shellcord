kill $(cat pipe/loopid)
rm pipe/loopid
kill $(cat pipe/sleepid)
rm pipe/sleepid


if $(cat pipe/broken)
then
  echo "Unexpeceted end! Sending end.."
  echo end > pipe/payload
else
  echo "Sending end.."
  echo end > pipe/payload
  echo "Awaiting end.."
  while [ "$(cat pipe/event)" != "end" ]
  do true; done
fi

rm pipe/payload
rm pipe/event
rm pipe/broken
