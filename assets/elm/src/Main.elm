module Main exposing (init, main, subscriptions, update, view)

import AddDocuments
import Browser
import Browser.Navigation as Nav
import Documents
import Home
import Html exposing (..)
import Html.Attributes exposing (..)
import Models
import Ports
import Settings
import Url



-- MAIN


main : Program () Models.State Models.Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = Models.UrlChanged
        , onUrlRequest = Models.LinkClicked
        }



-- MODEL


init : () -> Url.Url -> Nav.Key -> ( Models.State, Cmd Models.Msg )
init flags url key =
    let
        initialState =
            Models.modelFactory key url
    in
    case url.path of
        "/documents/add" ->
            AddDocuments.init flags key initialState

        _ ->
            ( initialState, Cmd.none )



-- UPDATE


update : Models.Msg -> Models.State -> ( Models.State, Cmd Models.Msg )
update msg model =
    case msg of
        Models.LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        Models.StartUpload ->
            ( { model | uploading = True }
            , AddDocuments.startUpload
            )

        Models.UploadCompleted ->
            ( { model | uploading = False }
            , Cmd.none
            )

        Models.UrlChanged url ->
            let
                newModel =
                    { model | url = url }
            in
            case url.path of
                "/documents/add" ->
                    AddDocuments.update newModel

                _ ->
                    ( newModel
                    , Cmd.none
                    )



-- SUBSCRIPTIONS


subscriptions : Models.State -> Sub Models.Msg
subscriptions _ =
    Ports.uploadCompleted (always Models.UploadCompleted)



-- VIEW


navbar : Html Models.Msg
navbar =
    Html.nav [ Html.Attributes.class "navbar navbar-expand-md navbar-dark fixed-top bg-dark" ]
        [ Html.a [ Html.Attributes.class "navbar-brand", Html.Attributes.href "/" ] [ Html.text "DMS42" ]
        , Html.div [ Html.Attributes.class "collapse navbar-collapse" ]
            [ Html.ul [ Html.Attributes.class "navbar-nav mr-auto" ]
                [ Html.li [ Html.Attributes.class "nav-item", Html.Attributes.classList [] ]
                    [ Html.a
                        [ Html.Attributes.class "nav-link"
                        , Html.Attributes.href "/"
                        ]
                        [ Html.text "Home" ]
                    ]
                , Html.li [ Html.Attributes.class "nav-item", Html.Attributes.classList [] ]
                    [ Html.a
                        [ Html.Attributes.class "nav-link"
                        , Html.Attributes.href "/documents"
                        ]
                        [ Html.text "Documents" ]
                    ]
                , Html.li [ Html.Attributes.class "nav-item", Html.Attributes.classList [] ]
                    [ Html.a
                        [ Html.Attributes.class "nav-link"
                        , Html.Attributes.href "/settings"
                        ]
                        [ Html.text "Settings" ]
                    ]
                ]
            ]
        ]


mainView : Models.State -> List (Html Models.Msg)
mainView state =
    let
        content =
            case state.url.path of
                "/documents" ->
                    Documents.view state

                "/settings" ->
                    Settings.view state

                "/documents/add" ->
                    AddDocuments.view state

                _ ->
                    Home.view state
    in
    [ navbar
    , Html.main_
        [ Html.Attributes.class "container"
        , Html.Attributes.attribute "role" "main"
        ]
        [ content ]
    ]


view : Models.State -> Browser.Document Models.Msg
view state =
    { title = "DMS42"
    , body = mainView state
    }
