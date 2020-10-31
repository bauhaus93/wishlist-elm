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
            wrap_row_col <| h2 [] [ text <| "{{ERROR_MESSAGE.PAGE_NOT_FOUND}}: '" ++ path ++ "'" ]


view_http_error : Http.Error -> Html msg
view_http_error error =
    wrap_row_col <|
        case error of
            Http.BadUrl str ->
                h2 [] [ text ("{{ ERROR_MESSAGE.BAD_URL }}" ++ str) ]

            Http.Timeout ->
                h2 [] [ text "{{ ERROR_MESSAGE.TIMEOUT }}" ]

            Http.NetworkError ->
                h2 [] [ text "{{ ERROR_MESSAGE.NETWORK_ERROR }}" ]

            Http.BadStatus status ->
                h2 []
                    [ text <|
                        "{{ ERROR_MESSAGE.BAD_STATUS }} "
                            ++ String.fromInt status
                    ]

            Http.BadBody msg ->
                div []
                    [ wrap_row_col <| h2 [] [ text "{{ ERROR_MESSAGE.BAD_BODY }}" ]
                    , wrap_row_col <| text msg
                    ]
