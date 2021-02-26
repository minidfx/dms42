module Middlewares.Alerts exposing (update)

import Helpers
import Models
import Msgs.Alerts
import Msgs.Main exposing (MiddlewareContext(..))
import Process
import Task


update : Msgs.Main.Msg -> Models.State -> MiddlewareContext
update msg state =
    case msg of
        Msgs.Main.AlertMsg alertMsg ->
            Continue <| internalUpdate alertMsg state

        _ ->
            Continue ( state, Cmd.none )


internalUpdate : Msgs.Alerts.Msg -> Models.State -> ( Models.State, Cmd Msgs.Main.Msg )
internalUpdate msg state =
    case msg of
        Msgs.Alerts.Close alertIndex ->
            let
                alerts =
                    state
                        |> Helpers.fluentSelect .alerts
                        |> List.filter (\{ id } -> (alertIndex == id) |> not)
            in
            ( { state | alerts = alerts }, Cmd.none )

        Msgs.Alerts.Publish { kind, timeout, message } ->
            let
                alerts =
                    state
                        |> Helpers.fluentSelect .alerts

                newId =
                    alerts
                        |> List.head
                        |> Maybe.andThen (\x -> Just <| x.id + 1)
                        |> Maybe.withDefault 0

                alert =
                    { kind = kind, id = newId, message = message }

                cmds =
                    case timeout of
                        Just x ->
                            [ Process.sleep (toFloat <| x * 1000)
                                |> Task.andThen
                                    (\_ ->
                                        newId
                                            |> (Msgs.Alerts.Close >> Msgs.Main.AlertMsg)
                                            |> Task.succeed
                                    )
                                |> Task.perform identity
                            ]

                        Nothing ->
                            []
            in
            ( { state | alerts = alert :: alerts }
            , Cmd.batch cmds
            )

        Msgs.Alerts.Nop ->
            ( state, Cmd.none )
