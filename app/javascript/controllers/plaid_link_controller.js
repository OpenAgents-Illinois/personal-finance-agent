import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    linkTokenUrl: String,
    exchangeUrl: String
  }

  async connect() {
    this.element.disabled = true
    this.element.textContent = "Loading..."

    try {
      const token = await this.fetchLinkToken()
      const handler = window.Plaid.create({
        token,
        onSuccess: (publicToken, _metadata) => this.onSuccess(publicToken),
        onExit: (_err, _metadata) => this.onExit()
      })
      this.element.disabled = false
      this.element.textContent = this.element.dataset.label || "Connect a bank account"
      this.handler = handler
    } catch (e) {
      this.element.textContent = "Error — reload and try again"
    }
  }

  open(event) {
    event.preventDefault()
    if (this.handler) this.handler.open()
  }

  async fetchLinkToken() {
    const resp = await fetch(this.linkTokenUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    })
    if (!resp.ok) throw new Error("link token request failed")
    const data = await resp.json()
    return data.link_token
  }

  async onSuccess(publicToken) {
    this.element.disabled = true
    this.element.textContent = "Connecting…"

    const resp = await fetch(this.exchangeUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ public_token: publicToken })
    })

    if (resp.ok) {
      window.location.reload()
    } else {
      this.element.disabled = false
      this.element.textContent = "Connection failed — try again"
    }
  }

  onExit() {
    this.element.disabled = false
    this.element.textContent = this.element.dataset.label || "Connect a bank account"
  }
}
