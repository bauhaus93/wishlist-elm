module Utility exposing (format_currency, leading_zeroes, month_to_num, timestamp_to_dm, timestamp_to_dmy, timestamp_to_hm, wrap_row_col, wrap_row_col_centered)

import Array
import Html exposing (..)
import Html.Attributes exposing (..)
import Time


wrap_row_col : Html msg -> Html msg
wrap_row_col wrapped_html =
    div [ class "row" ] [ div [ class "col" ] [ wrapped_html ] ]


wrap_row_col_centered : Html msg -> Html msg
wrap_row_col_centered wrapped_html =
    div [ class "row" ] [ div [ class "col text-center" ] [ wrapped_html ] ]


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


timestamp_to_dm : Int -> String
timestamp_to_dm time =
    let
        time_posix =
            Time.millisToPosix (time * 1000)

        month =
            String.fromInt <|
                month_to_num <|
                    Time.toMonth Time.utc time_posix

        day =
            String.fromInt <|
                Time.toDay Time.utc time_posix
    in
    String.join "." [ day, month ]


timestamp_to_hm : Int -> String
timestamp_to_hm time =
    let
        time_posix =
            Time.millisToPosix (time * 1000)

        hour =
            Time.toHour Time.utc time_posix
                |> String.fromInt
                |> leading_zeroes 2

        minute =
            Time.toMinute Time.utc time_posix
                |> String.fromInt
                |> leading_zeroes 2
    in
    String.join ":" [ hour, minute ]


leading_zeroes : Int -> String -> String
leading_zeroes max_len str =
    let
        zeroes =
            String.join "" (List.repeat (Basics.max 0 (max_len - String.length str)) "0")
    in
    zeroes ++ str


format_currency : String -> Float -> String
format_currency unit value =
    let
        needs_zero =
            abs value
                |> (*) 100
                |> floor
                |> modBy 100
                |> (\n -> n /= 0 && modBy 10 n == 0)
    in
    unit
        ++ " "
        ++ (case needs_zero of
                True ->
                    String.fromFloat value ++ "0"

                False ->
                    String.fromFloat value
           )


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
