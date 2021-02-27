module Views.Settings exposing (handleQueueInfo, init, update, view)

import Bootstrap.Card
import Bootstrap.Card.Block
import Bootstrap.Grid
import Bootstrap.Grid.Col
import Bootstrap.Grid.Row
import Factories
import Helpers
import Html exposing (Html)
import Http
import Json.Decode
import Models exposing (AlertKind(..))
import Msgs.Main
import Msgs.Settings
import String.Format
import Views.Alerts



-- Public members


view : Models.State -> List (Html Msgs.Main.Msg)
view state =
    let
        queueInfo =
            Maybe.withDefault Factories.queueInfoFactory <| state.queueInfo

        { processing, pending, cpus } =
            queueInfo
    in
    [ Bootstrap.Grid.row [ Bootstrap.Grid.Row.leftMd ]
        [ Bootstrap.Grid.col
            [ Bootstrap.Grid.Col.xs5, Bootstrap.Grid.Col.sm4, Bootstrap.Grid.Col.md3, Bootstrap.Grid.Col.lg2 ]
            [ Bootstrap.Card.config [ Bootstrap.Card.outlineInfo ]
                |> Bootstrap.Card.headerH5 [] [ Html.text "Workers" ]
                |> Bootstrap.Card.block []
                    [ Bootstrap.Card.Block.text [] [ Html.text <| String.Format.value (String.fromInt cpus) <| "Available: {{ }}" ]
                    , Bootstrap.Card.Block.text [] [ Html.text <| String.Format.value (String.fromInt processing) <| "Processing: {{ }}" ]
                    , Bootstrap.Card.Block.text [] [ Html.text <| String.Format.value (String.fromInt pending) <| "Pending: {{ }}" ]
                    ]
                |> Bootstrap.Card.view
            ]
        ]
    ]


init : Models.State -> ( Models.State, Cmd Msgs.Main.Msg )
init state =
    internalUpdate state Msgs.Settings.Home


update : Models.State -> Msgs.Settings.Msg -> ( Models.State, Cmd Msgs.Main.Msg )
update state msg =
    internalUpdate state msg


handleQueueInfo : Models.State -> Result Http.Error Models.QueueInfoResponse -> ( Models.State, Cmd Msgs.Main.Msg )
handleQueueInfo state result =
    let
        newState =
            { state | isLoading = False }
    in
    case result of
        Ok x ->
            ( { newState | queueInfo = Just x }, Cmd.none )

        Err message ->
            ( newState
            , Cmd.batch
                [ Views.Alerts.publish <|
                    { kind = Models.Danger
                    , message = Helpers.httpErrorToString message
                    , timeout = Nothing
                    }
                ]
            )



-- Private members


queueInfoDecoder : Json.Decode.Decoder Models.QueueInfoResponse
queueInfoDecoder =
    Json.Decode.map3 Models.QueueInfoResponse
        (Json.Decode.field "processing" Json.Decode.int)
        (Json.Decode.field "pending" Json.Decode.int)
        (Json.Decode.field "workers" Json.Decode.int)


getQueueInfo : Cmd Msgs.Main.Msg
getQueueInfo =
    Http.get
        { url = "/api/settings/queue"
        , expect = Http.expectJson (Msgs.Main.SettingsMsg << Msgs.Settings.GotQueueInfo) queueInfoDecoder
        }


internalUpdate : Models.State -> Msgs.Settings.Msg -> ( Models.State, Cmd Msgs.Main.Msg )
internalUpdate state msg =
    case msg of
        Msgs.Settings.GotQueueInfo result ->
            handleQueueInfo state result

        Msgs.Settings.Home ->
            ( { state | isLoading = True }, getQueueInfo )

        _ ->
            ( { state | isLoading = True }, getQueueInfo )
