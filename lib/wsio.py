from threading import Thread
from websocket import WebSocket
from sys import argv
from os import environ

host = argv [ 1 ]
pinp = argv [ 2 ]
pout = argv [ 3 ]
debug = environ [ "debug" ] == "true"

global trigger
trigger = False

def pay ( ws ) :
  global trigger
  while True :
    with open ( pinp, "r" ) as p :
      payload = p.read ( )
    if debug : print ( "wsio.py | I received a payload:", payload )
    if payload == "end\n" :
      ws.send ( '{"op":1,"d":null}' )
      trigger = True
      break
    else :
      ws.send ( payload )

ws = WebSocket ( )
try :
  ws.connect ( host )
except :
  if debug : print ( "wsio.py | I am sending an event: end" )
  with open ( pout, "w" ) as p :
    p.write ( "end" )
    exit ( )

s = Thread ( target = pay, args = ( ws, ))
s.start ( )

while True :
  try :
    event = ws.recv ( )
    if debug : print ( "wsio.py | I am sending an event:", event )
    with open ( pout, "w" ) as p :
      p.write ( event )
  except : break
  if not ws.connected : break
  if trigger : break


ws.close ( 1000 )
while True :
  try :
    if debug : print ( "wsio.py | I am sending an event: end" )
    with open ( pout, "w" ) as p :
      p.write ( "end" )
      break
  except BrokenPipeError : pass

s.join ( )
if debug : print ( "quittt" )
