module Pagination exposing (Model, Msg(..), init, to_items, update, view)

import ApiRoute exposing (ApiRoute)
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as D


type Msg a
    = GotItems (Result Http.Error (List a))
    | ExactPage Int
    | NextPage
    | PrevPage


type alias Model a =
    { items : List a
    , last_error : Maybe Error.Error
    , curr_page : Int
    , max_page : Maybe Int
    , request_route : Int -> ApiRoute
    , decoder : D.Decoder a
    }


update : Msg a -> Model a -> ( Model a, Cmd (Msg a) )
update msg model =
    case msg of
        NextPage ->
            next_page model

        PrevPage ->
            prev_page model

        ExactPage page ->
            request_page model page

        GotItems result ->
            case result of
                Ok items ->
                    ( { model | items = items }, Cmd.none )

                Err e ->
                    ( { model | last_error = Just (Error.HttpRequest e) }, Cmd.none )


view : Model a -> Html (Msg a)
view model =
    div [ class "row my-3" ]
        [ div [ class "col" ]
            [ div [ class "btn-group" ]
                [ button [ class "btn btn-secondary font-weight-bold", onClick PrevPage ] [ text "<" ]
                , button [ class "btn btn-secondary font-weight-bold", onClick NextPage ] [ text ">" ]
                ]
            ]
        ]


init : (Int -> ApiRoute) -> Maybe Int -> D.Decoder a -> Model a
init request_route maybe_max_page decoder =
    { items = []
    , last_error = Nothing
    , curr_page = 1
    , max_page = maybe_max_page
    , request_route = request_route
    , decoder = decoder
    }


to_items : Model a -> List a
to_items pagination =
    pagination.items


next_page : Model a -> ( Model a, Cmd (Msg a) )
next_page pagination =
    request_page pagination (pagination.curr_page + 1)


prev_page : Model a -> ( Model a, Cmd (Msg a) )
prev_page pagination =
    request_page pagination (pagination.curr_page - 1)


request_page : Model a -> Int -> ( Model a, Cmd (Msg a) )
request_page model page_num =
    ( { model | curr_page = page_num }
    , request_http (model.request_route page_num) (list_decoder model.decoder)
    )


request_http : ApiRoute -> D.Decoder (List a) -> Cmd (Msg a)
request_http route decoder =
    Http.get
        { url = ApiRoute.to_string route
        , expect = Http.expectJson GotItems decoder
        }


list_decoder : D.Decoder a -> D.Decoder (List a)
list_decoder decoder =
    D.list decoder
