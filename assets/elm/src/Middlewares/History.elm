module Middlewares.History exposing (update)

import Models
import Msgs.Main exposing (MiddlewareContext(..))


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update msg ({ history } as state) =
    case msg of
        Msgs.Main.UrlChanged url ->
            let
                newHistory =
                    (url :: history) |> List.take 10
            in
            Continue ( { state | history = newHistory }, Cmd.none )

        _ ->
            Continue ( state, Cmd.none )
