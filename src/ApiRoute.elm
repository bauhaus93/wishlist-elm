module ApiRoute exposing (ApiRoute(..), ArchiveQuery, TimelineQuery, from_url, parser, to_string)

import Url
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, parse, s, top)
import Url.Parser.Query as Query


type ApiRoute
    = LastWishlist
    | NewProducts
    | ProductArchive ArchiveQuery
    | Timeline TimelineQuery


type alias ArchiveQuery =
    { page : Maybe Int
    , per_page : Maybe Int
    }


type alias TimelineQuery =
    { resolution : Maybe Int
    , count : Maybe Int
    }


timeline_query : Query.Parser TimelineQuery
timeline_query =
    Query.map2 TimelineQuery (Query.int "resolution") (Query.int "count")


archive_query : Query.Parser ArchiveQuery
archive_query =
    Query.map2 ArchiveQuery (Query.int "page") (Query.int "per_page")


parser : Parser (ApiRoute -> a) a
parser =
    oneOf
        [ map LastWishlist (s "api" </> s "wishlist" </> s "last")
        , map NewProducts (s "api" </> s "product" </> s "newest")
        , map ProductArchive (s "api" </> s "product" </> s "archive" <?> archive_query)
        , map Timeline (s "api" </> s "timeline" </> s "points" <?> timeline_query)
        ]


from_url : Url.Url -> Maybe ApiRoute
from_url url =
    { url | path = url.path ++ Maybe.withDefault "" url.fragment, fragment = Nothing }
        |> parse parser


to_string : ApiRoute -> String
to_string route =
    let
        path_pieces =
            case route of
                LastWishlist ->
                    [ "api", "wishlist", "last" ]

                NewProducts ->
                    [ "api", "product", "newest" ]

                ProductArchive _ ->
                    [ "api", "product", "archive" ]

                Timeline _ ->
                    [ "api", "timeline", "points" ]

        query_pieces =
            case route of
                ProductArchive q ->
                    [ ( "page", String.fromInt <| Maybe.withDefault 1 q.page )
                    , ( "per_page", String.fromInt <| Maybe.withDefault 10 q.per_page )
                    ]

                Timeline q ->
                    [ ( "resolution", String.fromInt <| Maybe.withDefault 3600 q.resolution )
                    , ( "count", String.fromInt <| Maybe.withDefault 24 q.count )
                    ]

                _ ->
                    []

        query =
            case List.length query_pieces of
                0 ->
                    ""

                _ ->
                    "?"
                        ++ String.join "&" (List.map (\p -> Tuple.first p ++ "=" ++ Tuple.second p) query_pieces)
    in
    "/" ++ String.join "/" path_pieces ++ query
