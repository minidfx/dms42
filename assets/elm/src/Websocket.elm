module Websocket exposing (..)

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push


socketServer : String
socketServer =
    "ws://localhost:4000/socket/websocket"
