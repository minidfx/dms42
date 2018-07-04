module DocumentsView exposing (view)

import Html exposing (Html)
import Html.Attributes
import Models
import Rfc2822Datetime
import Dict exposing (Dict)
import Bootstrap.Alert
import Bootstrap.Card
import Bootstrap.Card.Block
import Bootstrap.Pagination
import Bootstrap.General.HAlign
import Helpers
import SharedViews


documentsList : Models.AppState -> Html Models.Msg
documentsList state =
    let
        { documents } =
            state
    in
        case documents of
            Nothing ->
                Html.div [] [ Bootstrap.Alert.simpleWarning [] [ Html.text "No documents" ] ]

            Just d ->
                let
                    documentAsList =
                        Dict.values d

                    pagination =
                        Bootstrap.Pagination.defaultConfig
                            |> Bootstrap.Pagination.ariaLabel "documents-pagination"
                            |> Bootstrap.Pagination.itemsList (itemsList state)
                            |> Bootstrap.Pagination.align Bootstrap.General.HAlign.centerXs
                            |> Bootstrap.Pagination.view
                in
                    case documentAsList of
                        [] ->
                            Html.div [] [ Bootstrap.Alert.simpleWarning [] [ Html.text "No documents" ] ]

                        list ->
                            let
                                cards =
                                    case (>) (List.length documentAsList) 50 of
                                        True ->
                                            Html.div []
                                                [ pagination
                                                , Html.div
                                                    [ Html.Attributes.class "row" ]
                                                    (List.map (\x -> SharedViews.card x) list)
                                                , pagination
                                                ]

                                        False ->
                                            Html.div
                                                [ Html.Attributes.class "row" ]
                                                (List.map (\x -> SharedViews.card x) list)
                            in
                                cards


itemsList : Models.AppState -> Bootstrap.Pagination.ListConfig a Models.Msg
itemsList { currentPages } =
    { selectedMsg = Models.ChangeDocumentsPage
    , prevItem = Just <| Bootstrap.Pagination.ListItem [] [ Html.text "Previous" ]
    , nextItem = Just <| Bootstrap.Pagination.ListItem [] [ Html.text "Next" ]
    , activeIdx = currentPages
    , data = []
    , itemFn = \x _ -> Bootstrap.Pagination.ListItem [] []
    , urlFn = \x _ -> "#documents"
    }


view : Models.AppState -> Html Models.Msg
view state =
    Html.div []
        [ Html.ul [ Html.Attributes.class "nav justify-content-center" ]
            [ Html.li [ Html.Attributes.class "nav-item" ]
                [ Html.a [ Html.Attributes.class "nav-link", Html.Attributes.href "#add-documents" ] [ Html.text "Add" ]
                ]
            ]
        , Html.hr [] []
        , documentsList state
        ]
