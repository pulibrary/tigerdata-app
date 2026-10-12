// eslint-disable-next-line import/prefer-default-export
export function copyPastePath() {
  // Sets the elements to the proper CSS classes once a value has been copied to the clipboard.
  function showIcon(button, copied) {
    const copyIcon = button.querySelector('.copy-paste-frames-icon');
    const checkIcon = button.querySelector('.copy-paste-check-icon');
    const labelEl = button.querySelector('.copy-project-path-label-text');
    if (!copyIcon || !checkIcon) return;

    copyIcon.toggleAttribute('hidden', copied);
    checkIcon.toggleAttribute('hidden', !copied);
    // aria-hidden keeps the title from being announced twice; the button label is the name.
    copyIcon.setAttribute('aria-hidden', 'true');
    checkIcon.setAttribute('aria-hidden', 'true');
    button.setAttribute(
      'aria-label',
      copied ? 'Copied' : copyIcon.querySelector('title').textContent,
    );
    if (labelEl) {
      labelEl.textContent = copied ? 'Copied!' : 'Copy';
      labelEl.classList.toggle('copy-project-path-label-normal', !copied);
      labelEl.classList.toggle('copy-project-path-label-copied', copied);
    }
  }

  function resetAllCopyButtons() {
    document.querySelectorAll('.copy-project-path-icon').forEach((button) => {
      button.classList.remove('copy-paste-error');
      showIcon(button, false);
    });
  }

  // Sets icon and label to indicate that an error happened when copying a value to the clipboard
  function errorCopyToClipboard(button, errorMsg) {
    button.classList.add('copy-paste-error');
    button.setAttribute('aria-label', 'Copy to clipboard failed');
    console.error(errorMsg);
  }

  function copyPath(value, button) {
    navigator.clipboard.writeText(value).then(
      () => {
        showIcon(button, true);
        setTimeout(() => {
          showIcon(button, false);
        }, 20000);
      },
      (error) => {
        console.error(error);
        errorCopyToClipboard(button, 'Copy to clipboard failed');
      },
    );
  }

  /* Copy path to the clipboard on the Dashboard and the Project Details */
  $('.copy-project-path-icon').on('click', (event) => {
    const button = event.currentTarget;
    resetAllCopyButtons();
    copyPath(button.dataset.url, button);
  });
}
