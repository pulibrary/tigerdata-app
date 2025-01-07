// @vitest-environment jsdom

import {
  // assert,
  describe,
  expect,
  it,
} from "vitest"
import { JSDOM } from "jsdom"
import { setTargetHtml } from "../entrypoints/helper"

describe("helper", () => {
  it("has a window", () => {
    expect(typeof window).toBe("object")
  })

  it("can test jQuery", () => {
    const dom = new JSDOM("<!DOCTYPE html><h1>Hello world</h1></html>")
    const h1 = dom.window.document.querySelector("h1")
    setTargetHtml({ target: h1 }, "Goodbye")
    expect(h1.innerHTML).toEqual("Goodbye")
  })
})
