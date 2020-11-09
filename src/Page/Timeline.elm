module Page.Timeline exposing (Model, Msg, init, to_last_error, to_nav_key, update, view)

import Api.Datapoint exposing (Datapoint)
import ApiRoute
import Browser
import Browser.Navigation as Nav
import ButtonGroup exposing (view_button, view_button_dropdown, view_button_group, view_button_group_dropdown)
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
import Utility exposing (timestamp_to_dm, timestamp_to_hm, wrap_responsive_alternative_sm, wrap_row_col, wrap_row_col_centered)


type alias Model =
    { nav_key : Nav.Key
    , time : Maybe Int
    , datapoints : Maybe (List Datapoint)
    , last_error : Maybe Error.Error
    , active_timespan : ActiveTimespan
    }


type ActiveTimespan
    = LastDay
    | LastWeek
    | LastMonth
    | Last3Month
    | LastYear


type Msg
    = RequestLastDay
    | RequestLastWeek
    | RequestLastMonth
    | RequestLast3Month
    | RequestLastYear
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
            ( { model | time = timestamp, active_timespan = LastDay }, request_days 1 timestamp )

        GotDatapoints result ->
            case result of
                Ok data ->
                    ( { model | datapoints = Just data }, Cmd.none )

                Err e ->
                    ( { model | last_error = Just (Error.HttpRequest e) }, Nav.pushUrl (to_nav_key model) (Route.to_string Route.Error) )

        RequestLastDay ->
            ( { model | active_timespan = LastDay }, request_days 1 model.time )

        RequestLastWeek ->
            ( { model | active_timespan = LastWeek }, request_weeks 1 model.time )

        RequestLastMonth ->
            ( { model | active_timespan = LastMonth }, request_months 1 model.time )

        RequestLast3Month ->
            ( { model | active_timespan = Last3Month }, request_months 3 model.time )

        RequestLastYear ->
            ( { model | active_timespan = LastYear }, request_years 1 model.time )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> ViewInfo Msg
view model =
    { title = "{{ PAGE.TITLE }}"
    , caption = "{{ PAGE.TIMELINE.CAPTION }}"
    , content =
        div []
            [ wrap_row_col <| view_chart model.datapoints
            , wrap_row_col <|
                div [ class "fixed-bottom my-3 mx-3" ]
                    [ view_request_buttons model.active_timespan
                    ]
            ]
    }


view_request_buttons : ActiveTimespan -> Html Msg
view_request_buttons active_timespan =
    let
        buttons : (Msg -> Bool -> String -> Html Msg) -> List (Html Msg)
        buttons wrap_fn =
            [ wrap_fn RequestLastDay (active_timespan == LastDay) "{{ LABEL.LAST_DAY }}"
            , wrap_fn RequestLastWeek (active_timespan == LastWeek) "{{ LABEL.LAST_WEEK }}"
            , wrap_fn RequestLastMonth (active_timespan == LastMonth) "{{ LABEL.LAST_MONTH }}"
            , wrap_fn RequestLast3Month (active_timespan == Last3Month) "{{ LABEL.LAST_3MONTH }}"
            , wrap_fn RequestLastYear (active_timespan == LastYear) "{{ LABEL.LAST_YEAR }}"
            ]
    in
    wrap_responsive_alternative_sm
        (div [ class "text-right" ] [ view_button_group_dropdown "{{ LABEL.TIMESPAN }}" <| buttons view_button_dropdown ])
        (div [ class "text-center" ] [ view_button_group (buttons view_button) ])


to_grouped_button : Msg -> ActiveTimespan -> ActiveTimespan -> String -> Html Msg
to_grouped_button msg button_timespan active_timespan label_string =
    let
        focus_class =
            if active_timespan == button_timespan then
                " focus"

            else
                ""
    in
    label [ class <| "btn btn-secondary" ++ focus_class ]
        [ input
            [ type_ "radio"
            , name "timespan"
            , attribute "autocomplete" "off"
            , onClick msg
            ]
            []
        , text label_string
        ]


to_dropdown_element : Msg -> ActiveTimespan -> ActiveTimespan -> String -> Html Msg
to_dropdown_element msg button_timespan active_timespan label_string =
    let
        focus_class =
            if active_timespan == button_timespan then
                " focus"

            else
                ""
    in
    label [ class <| "btn btn-block" ++ focus_class, attribute "style" "border-radius: 0px; margin: 0px;" ]
        [ input
            [ class "d-none"
            , type_ "radio"
            , name "timespan"
            , attribute "autocomplete" "off"
            , onClick msg
            ]
            []
        , text label_string
        ]


view_chart : Maybe (List Datapoint) -> Html Msg
view_chart maybe_datapoints =
    case maybe_datapoints of
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


request_days : Int -> Maybe Int -> Cmd Msg
request_days days_past maybe_now =
    let
        points =
            case days_past >= 365 of
                True ->
                    50

                False ->
                    20
    in
    request_datapoints
        { from_timestamp =
            maybe_now
                |> Maybe.andThen (\n -> Just (n - days_past * 24 * 3600))
        , count = Just points
        }


request_weeks : Int -> Maybe Int -> Cmd Msg
request_weeks weeks_past =
    request_days (7 * weeks_past)


request_months : Int -> Maybe Int -> Cmd Msg
request_months months_past =
    request_weeks (4 * months_past)


request_years : Int -> Maybe Int -> Cmd Msg
request_years years_past =
    request_days (365 * years_past)


init : Nav.Key -> ( Model, Cmd Msg )
init nav_key =
    ( { nav_key = nav_key
      , time = Nothing
      , datapoints = Nothing
      , last_error = Nothing
      , active_timespan = LastDay
      }
    , Task.perform GotTime Time.now
    )
