port module Game exposing (..)

-- Dependencies

import Html
import WebSocket
import String
import Phoenix.Socket
import Phoenix.Channel
import Json.Encode as JE
import Dict exposing (Dict)


-- Submodules

import PortsIn exposing (..)
import Update exposing (..)
import View exposing (..)
import Types.Params exposing (..)
import Types.Model exposing (..)
import Types.Game exposing (..)
import Types.Msg exposing (..)


main : Program Params Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Phoenix.Socket.listen model.phxSocket PhoenixMsg
        , onSendCompressedGame SendCompressedGame
        , onGameUpdate UpdateGame
        ]



-- Init the model *before* it gets its state from the server


init : Params -> ( Model, Cmd Msg )
init { id, playerId, host, playerName, themes, locale } =
    let
        game =
            Game "" [] [] 0 0 "eighties" False "public"

        payload =
            JE.object
                [ ( "playerId", JE.string playerId )
                , ( "playerName", JE.string playerName )
                ]

        channel =
            Phoenix.Channel.init ("game:" ++ id)
                |> Phoenix.Channel.withPayload payload

        socketInit =
            Phoenix.Socket.init ("ws://" ++ host ++ "/socket/websocket")
                |> Phoenix.Socket.on "update_game" ("game:" ++ id) ReceiveCompressedGame
                -- |> Phoenix.Socket.on "presence_state" ("game:" ++ id) HandlePresenceState
                -- |> Phoenix.Socket.on "presence_diff" ("game:" ++ id) HandlePresenceDiff
                |>
                    Phoenix.Socket.on "new_chat_msg" ("game:" ++ id) ReceiveMessage

        ( phxSocket, phxCmd ) =
            Phoenix.Socket.join channel socketInit
    in
        ( { game = game
          , playerId = playerId
          , playerName = playerName
          , host = host
          , playerTurn = 0
          , flippedIds = []
          , themes = themes
          , isCompleted = False
          , random = False
          , locale = locale
          , chatMessage = ""
          , chatMessages = []
          , phxSocket = socketInit
          , phxPresences = Dict.empty
          }
        , Cmd.map PhoenixMsg phxCmd
        )
