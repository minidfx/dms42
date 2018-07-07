module PageView exposing (view)

import Models
import Html exposing (Html)
import Html.Attributes
import Bootstrap.Navbar
import Bootstrap.Alert
import Routing
import Helpers


isActive : Models.AppState -> Routing.Route -> Bool
isActive { route } expectedRoute =
    (==) route expectedRoute


isDocumentsActive : Models.AppState -> Bool
isDocumentsActive state =
    let
        { route } =
            state
    in
        case route of
            Routing.Documents ->
                isActive state Routing.Documents

            Routing.AddDocuments ->
                isActive state (Routing.AddDocuments)

            Routing.Document x ->
                isActive state (Routing.Document x)

            Routing.DocumentProperties x ->
                isActive state (Routing.DocumentProperties x)

            _ ->
                False


navbar : Models.AppState -> Html Models.Msg
navbar state =
    Html.nav [ Html.Attributes.class "navbar navbar-expand-md navbar-dark fixed-top bg-dark" ]
        [ Html.a [ Html.Attributes.class "navbar-brand", Html.Attributes.href "/" ] [ Html.text "DMS42" ]
        , Html.div [ Html.Attributes.class "collapse navbar-collapse" ]
            [ Html.ul [ Html.Attributes.class "navbar-nav mr-auto" ]
                [ Html.li [ Html.Attributes.class "nav-item", Html.Attributes.classList [ ( "active", isActive state Routing.Home ) ] ]
                    [ Html.a
                        [ Html.Attributes.class "nav-link"
                        , Html.Attributes.href "#"
                        ]
                        [ Html.text "Home" ]
                    ]
                , Html.li [ Html.Attributes.class "nav-item", Html.Attributes.classList [ ( "active", isDocumentsActive state ) ] ]
                    [ Html.a
                        [ Html.Attributes.class "nav-link"
                        , Html.Attributes.href "#documents"
                        ]
                        [ Html.text "Documents" ]
                    ]
                , Html.li [ Html.Attributes.class "nav-item", Html.Attributes.classList [ ( "active", isActive state Routing.Settings ) ] ]
                    [ Html.a
                        [ Html.Attributes.class "nav-link"
                        , Html.Attributes.href "#settings"
                        ]
                        [ Html.text "Settings" ]
                    ]
                ]
            ]
        ]


view : Models.AppState -> (Models.AppState -> Html Models.Msg) -> Html Models.Msg
view state content =
    let
        { error } =
            state

        mainContent =
            case error of
                Nothing ->
                    [ content state ]

                Just x ->
                    [ Bootstrap.Alert.simpleDanger []
                        [ Html.text (Maybe.withDefault "" error) ]
                    , content state
                    ]
    in
        Html.div []
            [ navbar state
            , Html.main_
                [ Html.Attributes.class "container"
                , Html.Attributes.attribute "role" "main"
                ]
                mainContent
            ]
