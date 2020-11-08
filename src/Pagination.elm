module Pagination exposing (Model, Msg(..), init, to_items, to_last_error, update, view)

import ApiRoute exposing (ApiRoute)
import ButtonGroup exposing (view_button, view_button_group)
import Dict
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as D


type Msg a
    = GotItems (Result Http.Error (PaginatedResponse a))
    | ExactPage Int
    | NextPage
    | PrevPage


type alias Model a =
    { items : List a
    , last_error : Maybe Error.Error
    , curr_page : Int
    , per_page : Int
    , max_page : Maybe Int
    , request_route : Int -> Int -> ApiRoute
    , decoder : D.Decoder a
    }


type alias PaginatedResponse a =
    { items : List a, total_items : Maybe Int }


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
                Ok { items, total_items } ->
                    let
                        maybe_max_page =
                            case ( total_items, model.max_page ) of
                                ( Just new_max, Just old_max ) ->
                                    Just (new_max // model.per_page)

                                ( Just new_max, Nothing ) ->
                                    total_items
                                        |> Maybe.andThen (\i -> Just (i // model.per_page))

                                ( Nothing, Just old_max ) ->
                                    Just old_max

                                ( Nothing, Nothing ) ->
                                    Nothing
                    in
                    case List.length items of
                        0 ->
                            ( { model | curr_page = model.curr_page - 1, max_page = Just (model.curr_page - 1) }, Cmd.none )

                        _ ->
                            ( { model | items = items, max_page = maybe_max_page }, Cmd.none )

                Err e ->
                    ( { model | last_error = Just (Error.HttpRequest e) }, Cmd.none )


view : Model a -> Html (Msg a)
view model =
    let
        direct_buttons =
            case model.max_page of
                Just max ->
                    List.map (\i -> view_page_entry i model.curr_page) (List.range 1 max)

                Nothing ->
                    []

        full_pagination =
            case List.isEmpty model.items of
                True ->
                    div [] []

                False ->
                    view_button_group <|
                        [ view_button PrevPage False "<" ]
                            ++ direct_buttons
                            ++ [ view_button NextPage False ">" ]
    in
    div [ class "row my-3" ]
        [ div [ class "col text-center" ]
            [ full_pagination ]
        ]


init : (Int -> Int -> ApiRoute) -> D.Decoder a -> Model a
init request_route decoder =
    { items = []
    , last_error = Nothing
    , curr_page = 0
    , per_page = 10
    , max_page = Nothing
    , request_route = request_route
    , decoder = decoder
    }


view_page_entry : Int -> Int -> Html (Msg a)
view_page_entry entry_page curr_page =
    view_button (ExactPage entry_page) (entry_page == curr_page) (String.fromInt entry_page)


to_items : Model a -> List a
to_items pagination =
    pagination.items


to_last_error : Model a -> Maybe Error.Error
to_last_error model =
    model.last_error


next_page : Model a -> ( Model a, Cmd (Msg a) )
next_page pagination =
    let
        has_next =
            case pagination.max_page of
                Just max ->
                    pagination.curr_page < max

                Nothing ->
                    True
    in
    case has_next of
        True ->
            request_page pagination (pagination.curr_page + 1)

        False ->
            ( pagination, Cmd.none )


prev_page : Model a -> ( Model a, Cmd (Msg a) )
prev_page pagination =
    let
        has_prev =
            pagination.curr_page > 1
    in
    case has_prev of
        True ->
            request_page pagination (pagination.curr_page - 1)

        False ->
            ( pagination, Cmd.none )


request_page : Model a -> Int -> ( Model a, Cmd (Msg a) )
request_page model page_num =
    ( { model | curr_page = page_num }
    , request_http (model.request_route page_num model.per_page) model.decoder
    )


request_http : ApiRoute -> D.Decoder a -> Cmd (Msg a)
request_http route decoder =
    Http.get
        { url = ApiRoute.to_string route
        , expect = expect_json GotItems decoder
        }


expect_json : (Result Http.Error (PaginatedResponse a) -> msg) -> D.Decoder a -> Http.Expect msg
expect_json to_msg decoder =
    Http.expectStringResponse to_msg <|
        \response ->
            case response of
                Http.BadUrl_ url ->
                    Err (Http.BadUrl url)

                Http.Timeout_ ->
                    Err Http.Timeout

                Http.NetworkError_ ->
                    Err Http.NetworkError

                Http.BadStatus_ meta body ->
                    Err (Http.BadStatus meta.statusCode)

                Http.GoodStatus_ meta body ->
                    case D.decodeString (D.list decoder) body of
                        Ok value ->
                            Ok { items = value, total_items = to_total_max_items meta }

                        Err err ->
                            Err (Http.BadBody (D.errorToString err))


to_total_max_items : Http.Metadata -> Maybe Int
to_total_max_items meta =
    Dict.get (String.toLower "X-Paging-TotalRecordCount") meta.headers
        |> Maybe.andThen String.toInt
