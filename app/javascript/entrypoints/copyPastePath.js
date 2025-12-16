// eslint-disable-next-line import/prefer-default-export
export function copyPastePath() {
  // Sets the elements to the proper CSS classes once a value has been copied to the clipboard.
  function setCopiedToClipboard(iconEl, labelEl, normalClass, copiedClass) {
    $(iconEl).removeClass('copy-paste-frames');
    $(iconEl).addClass('copy-paste-check');
    $(labelEl).text('Copied!');
    $(labelEl).removeClass(normalClass);
    $(labelEl).addClass(copiedClass);
  }

  // Resets the elements to the proper CSS classes (e.g. displays as if the copy has not happened)
  function resetCopyToClipboard(iconEl, labelEl, normalClass, copiedClass) {
    $(labelEl).text('Copy');
    $(labelEl).removeClass(copiedClass);
    $(labelEl).addClass(normalClass);
    $(iconEl).addClass('copy-paste-frames');
    $(iconEl).removeClass('copy-paste-check');
  }

  // Sets icon and label to indicate that an error happened when copying a value to the clipboard
  function errorCopyToClipboard(iconEl, errorMsg) {
    $(iconEl).removeClass('copy-paste-frames');
    $(iconEl).addClass('copy-paste-error');
    console.error(errorMsg);
  }

  function copyPath(value, iconEl, labelEl, normalClass, copiedClass) {
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

  $('.copy-project-path-icon').on('click', (event) => {
    debugger;
    const projectPath = $(event.target).data('url');
    copyPath(
      projectPath,
      '#copy-project-path-button',
      '#copy-project-path-label',
      'copy-project-path-label-normal',
      'copy-project-path-label-copied',
    );
  });

  $(() => {
    $('.copy-project-path-icon').addClass('copy-paste-frames');
  });
}
