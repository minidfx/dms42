module HomeView exposing (view)

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Helpers
import PageView
import Models
import List
import SharedViews
import Bootstrap.Alert


view : Models.AppState -> Html Models.Msg
view { searchQuery, searchResult } =
    let
        cards =
            case searchResult of
                Nothing ->
                    Html.div [] []

                Just x ->
                    case x of
                        [] ->
                            Bootstrap.Alert.simpleWarning []
                                [ Html.text "No documents found" ]

                        y ->
                            Html.div [ Html.Attributes.class "row" ]
                                (List.map (\i -> SharedViews.card i) y)
    in
        Html.div [ Html.Attributes.class "home-search" ]
            [ Html.div
                [ Html.Attributes.class "input-group mb-3" ]
                [ Html.input
                    [ Html.Attributes.type_ "text"
                    , Html.Attributes.class "form-control"
                    , Html.Attributes.defaultValue (Maybe.withDefault "" searchQuery)
                    , (Html.Attributes.map Helpers.debounce <| Html.Events.onInput Models.Search)
                    ]
                    []
                , Html.div [ Html.Attributes.class "input-group-append" ]
                    [ Html.span [ Html.Attributes.class "input-group-text" ]
                        [ Html.span [ Html.Attributes.class "fas fa-search" ] []
                        ]
                    ]
                ]
            , cards
            ]
