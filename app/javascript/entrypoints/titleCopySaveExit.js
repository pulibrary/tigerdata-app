// eslint-disable-next-line import/prefer-default-export
export function titleCopySaveExit() {
  // copy the project title to the save and exit pop up so we show the user the latest
  $('#project_title').on('change', () => {
    const currentTitleValue = $('#project_title')[0].value;
    $('#project_title_exit')[0].value = currentTitleValue;
  });

  // copy the save and exit value back into the regular form on confirm so we make sure to get the new value
  $('save-exit-confirm').on('click', () => {
    const currentTitleValue = $('#project_title_exit')[0].value;
    if ($('#project_title').length === 1) $('#project_title')[0].value = currentTitleValue;
  });
}
