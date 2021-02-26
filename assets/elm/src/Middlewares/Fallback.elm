module Middlewares.Fallback exposing (..)

import Models
import Msgs.Main exposing (MiddlewareContext(..))


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update _ state =
    Continue ( state, Cmd.none )
