// Enforcing a value for the datalist utilizing custom validity
// Code idea taken from https://www.jotform.com/blog/html5-datalists-what-you-need-to-know-78024/
export default class UserDatalist {
  setupDatalistValidity() {
    // Find all inputs on the DOM which are bound to a datalist via their list attribute.
    const inputs = document.querySelectorAll('input[list]');
    for (let i = 0; i < inputs.length; i += 1) {
      // When the value of the input changes...
      const element = inputs[i];
      element.addEventListener('change', this.userRoleChange);

      // This is necessary for the initial page load
      this.userRoleChange.apply(element);
    }
  }

  userRoleChange() {
    let optionFound = false;
    const datalist = this.list;
    // Determine whether an option exists with the current value of the input.
    for (let j = 0; j < datalist.options.length; j += 1) {
      if (this.value === datalist.options[j].value) {
        optionFound = true;
        break;
      }
    }
    // use the setCustomValidity function of the Validation API
    // to provide an user feedback if the value does not exist in the datalist
    if (optionFound) {
      this.setCustomValidity('');
    } else if (this.required || this.value !== '') {
      this.setCustomValidity('Please select a valid value.');
    }

    const buttons = this.parentNode.querySelectorAll('[type=Submit]');
    if (this.value !== '') {
      for (let x = 0; x < buttons.length; x += 1) {
        buttons[x].disabled = !optionFound;
      }
    } else {
      for (let x = 0; x < buttons.length; x += 1) {
        buttons[x].disabled = true;
      }
    }

    if (this.required) {
      const formButtons = this.form.querySelectorAll('[value=Submit]');
      for (let k = 0; k < formButtons.length; k += 1) {
        formButtons[k].disabled = !optionFound;
      }

      // tell the user if there are errors
      this.reportValidity();
    }
  }
}
