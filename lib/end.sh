kill $(cat pipe/loopid)
rm pipe/loopid
kill $(cat pipe/sleepid)
rm pipe/sleepid


if $(cat pipe/broken)
then
  if $debug; then echo "Unexpeceted end! Sending end.."; fi
  echo end > pipe/payload
else
  if $debug; then echo "Sending end.."; fi
  echo end > pipe/payload
  if $debug; then echo "Awaiting end.."; fi
  while [ "$(cat pipe/event)" != "end" ]; do true; done
fi

rm pipe/payload
rm pipe/event
rm pipe/broken
