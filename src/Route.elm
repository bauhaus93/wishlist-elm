module Route exposing (Route(..), from_url, parser, replace_url, to_string)

import Browser.Navigation as Nav
import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, top)


type Route
    = Home
    | NewProducts
    | Archive
    | Timeline
    | Error


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map Home top
        , map NewProducts (s "new")
        , map Archive (s "archive")
        , map Error (s "error")
        , map Timeline (s "timeline")
        ]


from_url : Url.Url -> Maybe Route
from_url url =
    { url | path = url.path ++ Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> parse parser


to_string : Route -> String
to_string route =
    let
        pieces =
            case route of
                Home ->
                    []

                NewProducts ->
                    [ "new" ]

                Archive ->
                    [ "archive" ]

                Timeline ->
                    [ "timeline" ]

                Error ->
                    [ "error" ]
    in
    "/" ++ String.join "/" pieces


replace_url : Nav.Key -> Route -> Cmd msg
replace_url key route =
    Nav.replaceUrl key (to_string route)
