import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container", "display"]

    connect() {
        this.activeInput = null
    }

    open(event) {
        // Check mode setting
        const isEnabled = localStorage.getItem('numpadEnabled') === 'true';
        if (!isEnabled) return;

        this.activeInput = event.target
        this.containerTarget.classList.remove("d-none")
    }

    close() {
        this.containerTarget.classList.add("d-none")
        this.activeInput = null
    }

    input(event) {
        if (!this.activeInput) return

        const value = event.currentTarget.dataset.value
        this.activeInput.value = this.activeInput.value + value
        this.activeInput.dispatchEvent(new Event("input", { bubbles: true }))
        this.activeInput.dispatchEvent(new Event("change", { bubbles: true }))
    }

    backspace() {
        if (!this.activeInput) return

        const current = this.activeInput.value
        this.activeInput.value = current.slice(0, -1)
        this.activeInput.dispatchEvent(new Event("input", { bubbles: true }))
        this.activeInput.dispatchEvent(new Event("change", { bubbles: true }))
    }

    clear() {
        if (!this.activeInput) return

        this.activeInput.value = ""
        this.activeInput.dispatchEvent(new Event("input", { bubbles: true }))
        this.activeInput.dispatchEvent(new Event("change", { bubbles: true }))
    }
}
