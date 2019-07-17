module SharedViews exposing (alert, card)

import Bootstrap.Button
import Bootstrap.Card
import Bootstrap.Card.Block
import Bootstrap.Modal
import Helpers
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Models


alert : String -> Models.AppState -> String -> Html Models.Msg
alert key state title =
    Bootstrap.Modal.config (Models.CloseModal key)
        |> Bootstrap.Modal.large
        |> Bootstrap.Modal.h5 []
            [ Html.text title
            ]
        |> Bootstrap.Modal.footer []
            [ Bootstrap.Button.button
                [ Bootstrap.Button.outlinePrimary
                , Bootstrap.Button.attrs [ Html.Events.onClick <| Models.CloseModal key ]
                ]
                [ Html.text "Close" ]
            ]
        |> Bootstrap.Modal.view (Helpers.safeGetModalState key state)


card : Models.Document -> Html Models.Msg
card { datetimes, document_id } =
    let
        { inserted_datetime, updated_datetime } =
            datetimes
    in
    Html.div [ Html.Attributes.class "col-md-2" ]
        [ Html.a [ Html.Attributes.href ("#documents/" ++ document_id) ]
            [ Bootstrap.Card.config
                [ Bootstrap.Card.outlineInfo
                , Bootstrap.Card.attrs [ Html.Attributes.style [ ( "margin-bottom", "10px" ) ] ]
                ]
                |> Bootstrap.Card.footer [ Html.Attributes.class "text-center" ] [ Html.text (Helpers.dateTimeToString inserted_datetime) ]
                |> Bootstrap.Card.imgTop
                    [ Html.Attributes.src ("/documents/thumbnail/" ++ document_id)
                    , Html.Attributes.alt ("image-" ++ document_id)
                    ]
                    []
                |> Bootstrap.Card.view
            ]
        ]
