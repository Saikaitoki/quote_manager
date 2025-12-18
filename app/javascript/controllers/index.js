import { Application } from "@hotwired/stimulus"
import NumpadController from "./numpad_controller"

import AutosaveController from "./autosave_controller"

const application = Application.start()
application.register("numpad", NumpadController)
application.register("autosave", AutosaveController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
