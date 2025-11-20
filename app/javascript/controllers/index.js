import { application } from "./application"
import VotingController from "./voting_controller"
import KillLeftController from "./kill_left_controller"

application.register("voting", VotingController)
application.register("kill-left", KillLeftController)
