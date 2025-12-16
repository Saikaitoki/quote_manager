import { Application } from "@hotwired/stimulus"
import NumpadController from "./numpad_controller"

const application = Application.start()
application.register("numpad", NumpadController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }
