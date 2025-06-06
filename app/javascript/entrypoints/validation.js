// eslint-disable-next-line import/prefer-default-export
export function validationClear() {
  $('.form-field input').on('keyup', (event) => {
    const element = event.currentTarget;
    const errorElement = element.parentNode.querySelector('.input-error');
    if (element.value.length > 0 && errorElement.innerText === 'cannot be empty') {
      errorElement.innerHTML = '';
    }
  });
}
