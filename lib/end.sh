kill $(cat pipe/loopid)
rm pipe/loopid
kill $(cat pipe/sleepid)
rm pipe/sleepid


if [ "$broken" != "true" ]
then
  echo "Sending end.."
  echo end > pipe/payload
  echo "Awaiting end.."
  while [ "$(cat pipe/event)" != "end" ]
  do true; done
else
  echo "Unexpeceted end! Sending end.."
  echo end > pipe/payload
fi

rm pipe/payload
rm pipe/event

