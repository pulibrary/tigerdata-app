// eslint-disable-next-line import/prefer-default-export
export function titleCopySaveExit() {
  // Disable or enable the confirm button depending on if the title is empty
  function verify() {
    if (document.getElementById('project_title_exit').value.trim() === '') {
      document.getElementById('save-exit-confirm').disabled = true;
    } else {
      document.getElementById('save-exit-confirm').disabled = false;
    }
  }

  // copy the project title to the save and exit pop up so we show the user the latest
  $('#project_title').on('change', () => {
    const currentTitleValue = $('#project_title')[0].value;
    $('#project_title_exit')[0].value = currentTitleValue;
    verify();
  });

  // copy the save and exit value back into the regular form on confirm so we make sure to get the new value
  $('save-exit-confirm').on('click', () => {
    const currentTitleValue = $('#project_title_exit')[0].value;
    if ($('#project_title').length === 1) $('#project_title')[0].value = currentTitleValue;
    verify();
  });

  $('#project_title_exit').on('input', () => {
    verify();
  });
}
