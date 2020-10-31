module Page.Timeline exposing (Model, Msg, init, to_last_error, to_nav_key, update, view)

import Api.Datapoint exposing (Datapoint)
import ApiRoute
import Browser
import Browser.Navigation as Nav
import Error
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Colors as Colors
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk
import LineChart.Legends as Legends
import LineChart.Line as Line
import Page exposing (ViewInfo)
import Route
import Time
import Utility exposing (timestamp_to_dmy, wrap_row_col)


type alias Model =
    { nav_key : Nav.Key
    , datapoints : Maybe (List Datapoint)
    , last_error : Maybe Error.Error
    }


type Msg
    = RequestLastDay
    | RequestLastWeek
    | RequestLastMonth
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

        RequestLastDay ->
            ( model, request_last_day )

        RequestLastWeek ->
            ( model, request_last_week )

        RequestLastMonth ->
            ( model, request_last_month )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    let
        request_buttons =
            div [ class "btn-group btn-group-toggle", attribute "data-toggle" "buttons" ]
                [ button [ class "btn btn-secondary", type_ "radio", onClick RequestLastDay ] [ text "{{ LABEL.LAST_DAY }}" ]
                , button [ class "btn btn-secondary", type_ "radio", onClick RequestLastWeek ] [ text "{{ LABEL.LAST_WEEK }}" ]
                , button [ class "btn btn-secondary", type_ "radio", onClick RequestLastMonth ] [ text "{{ LABEL.LAST_MONTH }}" ]
                ]

        chart =
            case model.datapoints of
                Just datapoints ->
                    let
                        chart_config =
                            { x = Axis.time Time.utc 800 "{{ LABEL.TIME }}" (\d -> 1000 * d.slice)
                            , y = Axis.default 600 "{{ LABEL.VALUE }}" .value
                            , container = Container.responsive "chart-1"
                            , interpolation = Interpolation.monotone
                            , intersection = Intersection.default
                            , legends = Legends.none
                            , events = Events.default
                            , junk = Junk.default
                            , grid = Grid.default
                            , area = Area.default
                            , line = Line.wider 2.0
                            , dots = Dots.default
                            }

                        prepared_datapoints =
                            List.map (\d -> { slice = toFloat d.slice, value = toFloat d.value / 100.0 }) datapoints
                    in
                    LineChart.viewCustom chart_config [ LineChart.line Colors.blueLight Dots.none "{{ LABEL.VALUE }}" prepared_datapoints ]

                Nothing ->
                    div [] []
    in
    { title = "{{ PAGE.TIMELINE.TITLE }}"
    , caption = "{{ PAGE.TIMELINE.CAPTION }}"
    , content = div [ class "responsive" ] [ chart, wrap_row_col request_buttons ]
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
    request_datapoints { resolution = Just (30 * 3600), count = Just 30 }


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key
      , datapoints = Nothing
      , last_error = Nothing
      }
    , request_last_day
    )
