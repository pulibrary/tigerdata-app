// @vitest-environment jsdom

import { describe, it, expect } from "vitest"

import { JSDOM } from "jsdom"
import Mediaflux from "../components/mediaflux"

describe("Mediaflux", () => {
  const dom = new JSDOM(
    '<!DOCTYPE html><div class="mediaflux-status"></div></html>',
  )
  const { window } = dom
  const { document } = window
  const element = document.querySelector(".mediaflux-status")

  it("binds to the DOM", () => {
    const mediaflux = new Mediaflux(element)
    expect(mediaflux.element).toEqual(element)
  })
  describe("#setOnline", () => {
    it("updates the state of the instance", () => {
      const mediaflux = new Mediaflux(element)
      mediaflux.setOnline(true)

      expect(element.classList.contains("active")).toEqual(true)
      expect(element.classList.contains("inactive")).toEqual(false)
      mediaflux.setOnline(false)

      expect(element.classList.contains("active")).toEqual(false)
      expect(element.classList.contains("inactive")).toEqual(true)
    })
  })
})
