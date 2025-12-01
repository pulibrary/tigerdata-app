// eslint-disable-next-line import/prefer-default-export
export function copyPastePath() {

  // Sets the elements to the proper CSS classes once a value has been copied to the clipboard.
  function setCopiedToClipboard(iconEl, labelEl, normalClass, copiedClass) {
    $(iconEl).removeClass('bi-clipboard');
    $(iconEl).addClass('bi-clipboard-check');
    $(labelEl).text('COPIED');
    $(labelEl).removeClass(normalClass);
    $(labelEl).addClass(copiedClass);
  }

  // Resets the elements to the proper CSS classes (e.g. displays as if the copy has not happened)
  function resetCopyToClipboard(iconEl, labelEl, normalClass, copiedClass) {
    $(labelEl).text('COPY');
    $(labelEl).removeClass(copiedClass);
    $(labelEl).addClass(normalClass);
    $(iconEl).addClass('bi-clipboard');
    $(iconEl).removeClass('bi-clipboard-check');
  }

  // Sets icon and label to indicate that an error happened when copying a value to the clipboard
  function errorCopyToClipboard(iconEl, errorMsg) {
    $(iconEl).removeClass('bi-clipboard');
    $(iconEl).addClass('bi-clipboard-minus');
    console.error(errorMsg);
  }

  function copyPath(value, iconEl, labelEl, normalClass, copiedClass) {
    alert(value);
    // Copy value to the clipboard....
    navigator.clipboard.writeText(value).then(
      () => {
        // ...and notify the user
        setCopiedToClipboard(iconEl, labelEl, normalClass, copiedClass);
        setTimeout(() => {
          resetCopyToClipboard(iconEl, labelEl, normalClass, copiedClass);
        }, 20000);
      },
      () => {
        errorCopyToClipboard(iconEl, 'Copy to clipboard failed');
      },
    );
  }
  
  $('#copy-project-path-button').on('click', () => {
    const project_path = $('#copy-project-path-button').data('url');
    copyPath(
      project_path,
      '#copy-project-path-icon',
      '#copy-project-path-label',
      'copy-project-path-label-normal',
      'copy-project-path-label-copied',
    );
  });
}