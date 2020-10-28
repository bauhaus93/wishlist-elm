module Utility exposing (month_to_num, timestamp_to_dmy, wrap_row_col)

import Html exposing (..)
import Html.Attributes exposing (..)
import Time


wrap_row_col : Html msg -> Html msg
wrap_row_col wrapped_html =
    div [ class "row" ] [ div [ class "col" ] [ wrapped_html ] ]


timestamp_to_dmy : Int -> String
timestamp_to_dmy time =
    let
        time_posix =
            Time.millisToPosix (time * 1000)

        year =
            String.fromInt <|
                Time.toYear Time.utc time_posix

        month =
            String.fromInt <|
                month_to_num <|
                    Time.toMonth Time.utc time_posix

        day =
            String.fromInt <|
                Time.toDay Time.utc time_posix
    in
    String.join "." [ day, month, year ]


month_to_num : Time.Month -> Int
month_to_num mon =
    case mon of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12
