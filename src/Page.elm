module Page exposing (Page(..), ViewInfo, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Route


type Page
    = Home
    | NewProducts
    | Error
    | Other


type alias ViewInfo msg =
    { title : String
    , caption : String
    , content : Html msg
    }


view : Page -> ViewInfo msg -> Browser.Document msg
view page { title, caption, content } =
    { title = title
    , body =
        view_navbar
            :: [ div [ class "container" ]
                    [ div [ class "row my-3" ] [ div [ class "col" ] [ h1 [] [ text caption ] ] ]
                    , div [ class "row my-3" ] [ div [ class "col" ] [ content ] ]
                    ]
               ]
    }


navbar_elements : List { route : Route.Route, label : String }
navbar_elements =
    [ { route = Route.Home, label = "Aktuell" }
    , { route = Route.NewProducts, label = "Neues" }
    ]


view_navbar : Html msg
view_navbar =
    let
        list_items =
            List.map
                (\{ route, label } ->
                    li [ class "nav-item" ] [ a [ class "nav-link", href (Route.to_string route) ] [ text label ] ]
                )
                navbar_elements

        navbar_toggle_button =
            button
                [ class "navbar-toggler"
                , type_ "button"
                , attribute "data-toggle" "collapse"
                , attribute "data-target" "#navbarSupportedContent"
                , attribute "aria-controls" "navbarSupportedContent"
                , attribute "aria-expanded" "false"
                , attribute "aria-label" "Toggle navigation"
                ]
                [ span [ class "navbar-toggler-icon" ] [] ]
    in
    nav [ class "navbar sticky-top navbar-expand-sm navbar-dark bg-dark" ]
        [ a [ class "navbar-brand", href (Route.to_string Route.Home) ] [ text "Winglers Liste" ]
        , navbar_toggle_button
        , div [ class "collapse navbar-collapse mr-auto", id "navbarSupportedContent" ]
            [ ul [ class "navbar-nav", id "navigation" ] list_items
            ]
        ]
