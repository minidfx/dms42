module DocumentsView exposing (view)

import Html exposing (Html)
import Html.Attributes
import Models
import Rfc2822Datetime
import Dict exposing (Dict)
import Bootstrap.Alert
import Bootstrap.Card
import Bootstrap.Card.Block
import Helpers
import SharedViews


documentsList : Maybe (Dict String Models.Document) -> Html Models.Msg
documentsList documents =
    case documents of
        Nothing ->
            Html.div [] [ Bootstrap.Alert.simpleWarning [] [ Html.text "No documents" ] ]

        Just d ->
            let
                documentAsList =
                    Dict.values d
            in
                case documentAsList of
                    [] ->
                        Html.div [] [ Bootstrap.Alert.simpleWarning [] [ Html.text "No documents" ] ]

                    list ->
                        Html.div [ Html.Attributes.class "row" ] (List.map (\x -> SharedViews.card x) list)


view : Models.AppState -> Html Models.Msg
view { documents } =
    Html.div []
        [ Html.ul [ Html.Attributes.class "nav justify-content-center" ]
            [ Html.li [ Html.Attributes.class "nav-item" ]
                [ Html.a [ Html.Attributes.class "nav-link", Html.Attributes.href "#add-documents" ] [ Html.text "Add" ]
                ]
            ]
        , Html.hr [] []
        , documentsList documents
        ]
