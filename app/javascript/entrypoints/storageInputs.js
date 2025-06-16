function showHidden(event) {
  const toggleElement = event.currentTarget;
  const element = toggleElement.parentNode.querySelector('.hidden-div');
  element.hidden = false;
}

function selectStorage(event) {
  const storageElement = event.currentTarget;
  storageElement.querySelector('input').click();
}

// eslint-disable-next-line import/prefer-default-export
export function storageInputs() {
  $('.hidden-toggle').on('click', (event) => {
    showHidden(event);
  });

  $('.hidden-toggle').keyup((event) => {
    if (event.keyCode === 13) showHidden(event);
  });

  $('.quota-option').keyup((event) => {
    if (event.keyCode === 13) selectStorage(event);
  });
}
