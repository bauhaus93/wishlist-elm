module Page.Error exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Page exposing (ViewInfo)


type alias Model =
    { nav_key : Nav.Key
    , error : Maybe Http.Error
    }


type Msg
    = NoMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    let
        error_content =
            case model.error of
                Just e ->
                    view_error e

                Nothing ->
                    h2 [] [ text "Alles ok" ]
    in
    { title = "Fehler"
    , caption = "Fehler"
    , content = error_content
    }


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


to_last_error : Model -> Maybe Http.Error
to_last_error model =
    model.error


init : Nav.Key -> Maybe Http.Error -> ( Model, Cmd Msg )
init nav_key error =
    ( { nav_key = nav_key
      , error = error
      }
    , Cmd.none
    )


view_error : Http.Error -> Html Msg
view_error error =
    case error of
        Http.BadUrl str ->
            h2 [] [ text ("Ungültige URL:" ++ str) ]

        Http.Timeout ->
            h2 [] [ text "Zeitüberschreitung bei Anfrage" ]

        Http.NetworkError ->
            h2 [] [ text "Konnte keine Verbindung herstellen" ]

        Http.BadStatus status ->
            h2 []
                [ text <|
                    "HTTP "
                        ++ String.fromInt status
                ]

        Http.BadBody msg ->
            div []
                [ div [ class "row" ] [ div [ class "col" ] [ h2 [] [ text "Unerwarteter Inhalt" ] ] ]
                , div [ class "row" ] [ div [ class "col" ] [ text msg ] ]
                ]
