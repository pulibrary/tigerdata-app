// eslint-disable-next-line import/prefer-default-export
export function showCreateScript(url) {
  $("#create-script-btn").on("click", (el) => {
    $.ajax({
      type: "GET",
      url,
      success(data) {
        const lines = data.script.split("\n")
        let atermScript = ""
        for (let i = 0; i < lines.length; i += 1) {
          const line = lines[i]
          const prefixSize = line.length - line.trimLeft().length
          const spaces = "&nbsp;".repeat(prefixSize)
          atermScript += `${spaces + line}<br/>`
        }
        $("#create-script-text").html(atermScript)
      },
    })
    el.preventDefault()
  })
}
