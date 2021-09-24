from threading import Thread
from websocket import WebSocket
from sys import argv

host = argv [ 1 ]
pinp = argv [ 2 ]
pout = argv [ 3 ]

global trigger
trigger = False

def pay ( ws ) :
  global trigger
  while True :
    with open ( pinp, "r" ) as p :
      payload = p.read ( )
    if payload == "end\n" :
      ws.send ( '{"op":1,"d":null}' )
      trigger = True
      break
    else :
      ws.send ( payload )

ws = WebSocket ( )
ws.connect ( host )

s = Thread ( target = pay, args = ( ws, ))
s.start ( )

while True :
  try :
    event = ws.recv ( )
    with open ( pout, "w" ) as p :
      p.write ( event )
  except : break
  if not ws.connected : break
  if trigger : break


ws.close ( 1000 )
while True :
  try :
    with open ( pout, "w" ) as p :
      p.write ( "end" )
      break
  except BrokenPipeError : pass

s.join ( )
print("quittt")
