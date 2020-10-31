module Page.Timeline exposing (Model, Msg, init, to_last_error, to_nav_key, update, view)

import Api.Datapoint exposing (Datapoint)
import ApiRoute
import Browser
import Browser.Navigation as Nav
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import LineChart
import Page exposing (ViewInfo)
import ProductTable exposing (view_product_table)
import Route
import Task
import Time
import Utility exposing (timestamp_to_dmy)


type alias Model =
    { nav_key : Nav.Key
    , datapoints : Maybe (List Datapoint)
    , last_error : Maybe Error.Error
    }


type Msg
    = RequestDatapoints ApiRoute.TimelineQuery
    | GotDatapoints (Result Http.Error (List Datapoint))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotDatapoints result ->
            case result of
                Ok data ->
                    ( { model | datapoints = Just data }, Cmd.none )

                Err e ->
                    ( { model | last_error = Just (Error.HttpRequest e) }, Nav.pushUrl (to_nav_key model) (Route.to_string Route.Error) )

        RequestDatapoints req_data ->
            ( model, request_datapoints req_data )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    let
        chart =
            case model.datapoints of
                Just datapoints ->
                    LineChart.view1 .slice .value (List.map (\d -> { slice = toFloat d.slice, value = toFloat d.value / 100.0 }) datapoints)

                Nothing ->
                    div [] []
    in
    { title = "{{ PAGE.TIMELINE.TITLE }}"
    , caption = "{{ PAGE.TIMELINE.CAPTION }}"
    , content = div [ class "responsive" ] [ chart ]
    }


to_nav_key : Model -> Nav.Key
to_nav_key model =
    model.nav_key


to_last_error : Model -> Maybe Error.Error
to_last_error model =
    model.last_error


request_datapoints : ApiRoute.TimelineQuery -> Cmd Msg
request_datapoints query =
    Http.get
        { url = ApiRoute.to_string (ApiRoute.Timeline query)
        , expect = Http.expectJson GotDatapoints Api.Datapoint.list_decoder
        }


request_last_day : Cmd Msg
request_last_day =
    request_datapoints { resolution = Just 3600, count = Just 24 }


request_last_week : Cmd Msg
request_last_week =
    request_datapoints { resolution = Just (7 * 3600), count = Just 7 }


request_last_month : Cmd Msg
request_last_month =
    request_datapoints { resolution = Just (30 * 7 * 3600), count = Just 30 }


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key
      , datapoints = Nothing
      , last_error = Nothing
      }
    , request_last_day
    )
