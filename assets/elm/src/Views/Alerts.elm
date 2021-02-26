module Views.Alerts exposing (publish)

import Models
import Msgs.Alerts
import Msgs.Main
import Task


publish : Models.AlertRequest -> Cmd Msgs.Main.Msg
publish request =
    request
        |> Msgs.Alerts.Publish
        |> Msgs.Main.AlertMsg
        |> Task.succeed
        |> Task.perform identity
