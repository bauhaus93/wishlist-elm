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
import LineChart.Axis.Line as AxisLine
import LineChart.Axis.Range as Range
import LineChart.Axis.Tick as Tick
import LineChart.Axis.Ticks as Ticks
import LineChart.Axis.Title as Title
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
import Task
import Time
import Utility exposing (timestamp_to_dm, timestamp_to_hm, wrap_row_col, wrap_row_col_centered)


type alias Model =
    { nav_key : Nav.Key
    , time : Maybe Int
    , datapoints : Maybe (List Datapoint)
    , last_error : Maybe Error.Error
    }


type Msg
    = RequestLastDay
    | RequestLastWeek
    | RequestLastMonth
    | GotTime Time.Posix
    | GotDatapoints (Result Http.Error (List Datapoint))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTime time ->
            let
                timestamp =
                    Just (Time.posixToMillis time // 1000)
            in
            ( { model | time = timestamp }, request_last_day timestamp )

        GotDatapoints result ->
            case result of
                Ok data ->
                    ( { model | datapoints = Just data }, Cmd.none )

                Err e ->
                    ( { model | last_error = Just (Error.HttpRequest e) }, Nav.pushUrl (to_nav_key model) (Route.to_string Route.Error) )

        RequestLastDay ->
            ( model, request_last_day model.time )

        RequestLastWeek ->
            ( model, request_last_week model.time )

        RequestLastMonth ->
            ( model, request_last_month model.time )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    let
        timespan_button : Msg -> Bool -> String -> Html Msg
        timespan_button msg is_active label_string =
            label [ class "btn btn-secondary" ]
                [ input [ type_ "radio", name "timespan", attribute "autocomplete" "off", onClick msg ] []
                , text label_string
                ]

        request_buttons =
            div [ class "btn-group btn-group-toggle", attribute "data-toggle" "buttons" ]
                [ timespan_button RequestLastDay True "{{ LABEL.LAST_DAY }}"
                , timespan_button RequestLastWeek False "{{ LABEL.LAST_WEEK }}"
                , timespan_button RequestLastMonth False "{{ LABEL.LAST_MONTH }}"
                ]

        chart =
            case model.datapoints of
                Just datapoints ->
                    let
                        slices =
                            List.map (\d -> d.slice) datapoints

                        high =
                            List.maximum slices
                                |> Maybe.withDefault 0

                        low =
                            List.minimum slices
                                |> Maybe.withDefault 0

                        timespan =
                            high - low

                        chart_config =
                            { x = x_axis_config timespan
                            , y = Axis.default 400 "{{ LABEL.VALUE }}" .value
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
                            List.map (\d -> { slice = d.slice, value = toFloat d.value / 100.0 }) datapoints
                    in
                    LineChart.viewCustom chart_config [ LineChart.line Colors.blue Dots.none "{{ LABEL.VALUE }}" prepared_datapoints ]

                Nothing ->
                    div [] []
    in
    { title = "{{ PAGE.TITLE }}"
    , caption = "{{ PAGE.TIMELINE.CAPTION }}"
    , content = div [] [ wrap_row_col chart, wrap_row_col_centered request_buttons ]
    }


x_axis_config : Int -> Axis.Config { slice : Int, value : Float } msg
x_axis_config timespan =
    Axis.custom
        { title = Title.default "{{ LABEL.TIME }}"
        , variable = \d -> Just (toFloat d.slice)
        , pixels = 600
        , range = Range.default
        , axisLine = AxisLine.full Colors.black
        , ticks = Ticks.intCustom 6 (custom_tick timespan)
        }


custom_tick : Int -> Int -> Tick.Config msg
custom_tick timespan n =
    let
        formatter : Int -> String
        formatter =
            case timespan <= 48 * 3600 of
                True ->
                    \v -> timestamp_to_hm (v - modBy 3600 v)

                False ->
                    timestamp_to_dm
    in
    Tick.custom
        { position = toFloat n
        , color = Colors.black
        , width = 2
        , length = 2
        , grid = True
        , direction = Tick.negative
        , label = Just (Junk.label Colors.black (formatter n))
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


request_last_day : Maybe Int -> Cmd Msg
request_last_day maybe_now =
    request_datapoints
        { from_timestamp =
            maybe_now
                |> Maybe.andThen (\n -> Just (n - 24 * 3600))
        , count = Just 24
        }


request_last_week : Maybe Int -> Cmd Msg
request_last_week maybe_now =
    request_datapoints
        { from_timestamp =
            maybe_now
                |> Maybe.andThen (\n -> Just (n - 7 * 24 * 3600))
        , count = Just 14
        }


request_last_month : Maybe Int -> Cmd Msg
request_last_month maybe_now =
    request_datapoints
        { from_timestamp =
            maybe_now
                |> Maybe.andThen (\n -> Just (n - 30 * 24 * 3600))
        , count = Just 30
        }


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key
      , time = Nothing
      , datapoints = Nothing
      , last_error = Nothing
      }
    , Task.perform GotTime Time.now
    )
