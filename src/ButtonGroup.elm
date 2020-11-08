module ButtonGroup exposing (view_button, view_button_dropdown, view_button_group, view_button_group_dropdown)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


view_button : msg -> Bool -> String -> Html msg
view_button msg selected label_string =
    label [ class <| "btn btn-secondary" ++ to_class selected ]
        [ input
            [ type_ "radio"
            , attribute "autocomplete" "off"
            , onClick msg
            ]
            []
        , text label_string
        ]


view_button_dropdown : msg -> Bool -> String -> Html msg
view_button_dropdown msg selected label_string =
    label
        [ class <| "btn btn-block" ++ to_class selected
        , attribute "style" "border-radius: 0px; margin: 0px;"
        ]
        [ input
            [ class "d-none"
            , type_ "radio"
            , attribute "autocomplete" "off"
            , onClick msg
            ]
            []
        , text label_string
        ]


view_button_group : List (Html msg) -> Html msg
view_button_group grouped_buttons =
    div [ class "btn-group btn-group-toggle", attribute "data-toggle" "buttons" ] grouped_buttons


view_button_group_dropdown : String -> List (Html msg) -> Html msg
view_button_group_dropdown dropdown_label dropdown_buttons =
    div [ class "dropdown" ]
        [ button
            [ class "btn btn-secondary dropdown-toggle"
            , type_ "button"
            , attribute "data-toggle" "dropdown"
            ]
            [ text dropdown_label
            , span [ class "caret" ] []
            ]
        , ul [ class "dropdown-menu" ]
            (List.map (\b -> li [] [ b ]) dropdown_buttons)
        ]


to_class : Bool -> String
to_class selected =
    case selected of
        True ->
            " focus active"

        False ->
            ""
