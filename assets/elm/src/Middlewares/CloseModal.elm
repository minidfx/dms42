module Middlewares.CloseModal exposing (update)

import Bootstrap.Modal
import Models
import Msgs.Main exposing (MiddlewareContext(..))
import Task


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update msg ({ modalVisibility } as state) =
    case msg of
        Msgs.Main.UrlChanged url ->
            case modalVisibility of
                Just x ->
                    if x.visibility /= Bootstrap.Modal.hidden then
                        Break
                            ( state
                            , Cmd.batch
                                [ Msgs.Main.CloseModal |> Task.succeed |> Task.perform identity
                                , Msgs.Main.UrlChanged url |> Task.succeed |> Task.perform identity
                                ]
                            )

                    else
                        Continue ( state, Cmd.none )

                Nothing ->
                    Continue ( state, Cmd.none )

        _ ->
            Continue ( state, Cmd.none )
