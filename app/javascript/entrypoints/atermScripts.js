// eslint-disable-next-line import/prefer-default-export
export function showCreateScript(url) {
  $('#create-script-btn').on('click', (el) => {
    $.ajax({
      type: 'GET',
      url: url,
      success(data) {
        const lines = data.script.split("\n");
        let atermScript = "";
        for(var i=0; i < lines.length; i++) {
          let line = lines[i];
          let prefixSize = line.length - line.trimLeft().length;
          let spaces = "&nbsp;".repeat(prefixSize)
          atermScript += spaces + line + "<br/>";
        }
        $('#create-script-text').html(atermScript);
      },
    });
    el.preventDefault();
  });
}
