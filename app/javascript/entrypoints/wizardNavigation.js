function saveOnClick(event) {
  // Prevent the normal click event from continue executing...
  event.preventDefault();

  // ...and instead submit the form so that we save the current edits and go to the url
  let submitButton = document.querySelectorAll('input[type=submit][value=Next]')[0];
  if (submitButton === undefined) {
    [submitButton] = document.querySelectorAll('input[type=submit][value=Submit]');
  }
  const redirectUrl = event.target.href;
  const input = document.createElement('input');
  input.type = 'hidden';
  input.value = redirectUrl;
  input.name = 'redirectUrl';
  submitButton.parentElement.appendChild(input);
  document.body.style.cursor = 'wait';
  submitButton.click();
  return false;
}

// eslint-disable-next-line import/prefer-default-export
export function wizardNavigation() {
  const steps = document.getElementsByClassName('go-to-step');

  // only capture clicks to links if we are in the wizard
  if (steps.length > 0) {
    const crumbs = document.getElementsByClassName('breadcrumb-link');
    const allItems = Array.from(steps).concat(Array.from(crumbs));
    allItems.forEach((item) => {
      item.addEventListener('click', saveOnClick);
    });
  }
}
