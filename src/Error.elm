module Error exposing (Error(..), view_error)

import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Utility exposing (wrap_row_col)


type Error
    = HttpRequest Http.Error
    | NotFound String


view_error : Error -> Html msg
view_error error =
    case error of
        HttpRequest err ->
            view_http_error err

        NotFound path ->
            wrap_row_col <| h2 [] [ text <| "Seite '" ++ path ++ "' konnte etzadla nicht gefunden werden" ]


view_http_error : Http.Error -> Html msg
view_http_error error =
    h2 []
        [ wrap_row_col <| text "Fehler bei HTTP Anfrage"
        , wrap_row_col <|
            case error of
                Http.BadUrl str ->
                    h3 [] [ text ("Ungültige URL:" ++ str) ]

                Http.Timeout ->
                    h3 [] [ text "Zeitüberschreitung bei Anfrage" ]

                Http.NetworkError ->
                    h3 [] [ text "Konnte keine Verbindung herstellen" ]

                Http.BadStatus status ->
                    h3 []
                        [ text <|
                            "HTTP "
                                ++ String.fromInt status
                        ]

                Http.BadBody msg ->
                    div []
                        [ wrap_row_col <| h2 [] [ text "Unerwarteter Inhalt" ]
                        , wrap_row_col <| text msg
                        ]
        ]
