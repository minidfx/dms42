module Views.Settings exposing (handleQueueInfo, init, update, view)

import Factories
import Helpers
import Html exposing (Html)
import Html.Attributes
import Http
import Json.Decode
import Models



-- Public members


view : Models.State -> List (Html Models.Msg)
view state =
    let
        queueInfo =
            Maybe.withDefault Factories.queueInfoFactory <| state.queueInfo

        { processing, pending, cpus } =
            queueInfo
    in
    [ Html.div [ Html.Attributes.class "d-flex empty" ]
        [ Html.dl []
            [ Html.dt [] [ Html.text "Workers" ]
            , Html.dd [] [ Html.text <| String.fromInt cpus ]
            , Html.dt [] [ Html.text "Processing" ]
            , Html.dd [] [ Html.text <| String.fromInt processing ]
            , Html.dt [] [ Html.text "Pending" ]
            , Html.dd [] [ Html.text <| String.fromInt pending ]
            ]
        ]
    ]


init : Models.State -> ( Models.State, Cmd Models.Msg )
init state =
    internalUpdate state


update : Models.State -> ( Models.State, Cmd Models.Msg )
update state =
    internalUpdate state


handleQueueInfo : Models.State -> Result Http.Error Models.QueueInfoResponse -> ( Models.State, Cmd Models.Msg )
handleQueueInfo state result =
    case result of
        Ok x ->
            ( { state | queueInfo = Just x, isLoading = False }, Cmd.none )

        Err message ->
            ( { state | error = Just <| Helpers.httpErrorToString message, isLoading = False }, Cmd.none )



-- Private members


queueInfoDecoder : Json.Decode.Decoder Models.QueueInfoResponse
queueInfoDecoder =
    Json.Decode.map3 Models.QueueInfoResponse
        (Json.Decode.field "processing" Json.Decode.int)
        (Json.Decode.field "pending" Json.Decode.int)
        (Json.Decode.field "workers" Json.Decode.int)


getQueueInfo : Cmd Models.Msg
getQueueInfo =
    Http.get
        { url = "/api/settings/queue"
        , expect = Http.expectJson Models.GotQueueInfo queueInfoDecoder
        }


internalUpdate : Models.State -> ( Models.State, Cmd Models.Msg )
internalUpdate state =
    ( { state | isLoading = True }, getQueueInfo )
