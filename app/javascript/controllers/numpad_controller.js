import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container", "display"]

    connect() {
        this.activeInput = null
    }

    open(event) {
        this.activeInput = event.target
        this.containerTarget.classList.remove("d-none")
        // Prevent default keyboard on mobile if possible, though inputmode="numeric" handles that nicely too (or inputmode="none" to block soft keyboard completely?)
        // User wanted "numeric priority" so inputmode="numeric" is best.
        // If they want to BLOCK the native keyboard to use ONLY this one, inputmode="none" is better.
        // But they asked for "numeric priority display function", implying they MIGHT use the native one.
        // Let's stick to inputmode="numeric" on the field itself.
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
