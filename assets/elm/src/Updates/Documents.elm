module Updates.Documents exposing (..)

import Models.Msgs exposing (..)


dispatch : Models.Application.AppModel -> Cmd Models.Msgs.Msg
dispatch model msg =
    ( model, msg )
