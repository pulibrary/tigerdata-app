// Enforcing a value for the datalist utilizing custom validity
// Code idea taken from https://www.jotform.com/blog/html5-datalists-what-you-need-to-know-78024/
export default class UserDatalist {
  setupDatalistValidity() {
  // Find all inputs on the DOM which are bound to a datalist via their list attribute.
    const inputs = document.querySelectorAll('input[list]');
    for (let i = 0; i < inputs.length; i += 1) {
    // When the value of the input changes...
      inputs[i].addEventListener('change', this.userRoleChange);
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
      this.parentNode.querySelectorAll('a');
      const buttons = this.parentNode.querySelectorAll('[type=submit]');
      for (let k = 0; k < buttons.length; k += 1) {
        buttons[k].disabled = false;
      }
    } else {
      this.setCustomValidity('Please select a valid value.');
      const buttons = this.parentNode.querySelectorAll('[type=submit]');
      for (let x = 0; x < buttons.length; x += 1) {
        buttons[x].disabled = true;
      }
    }
    // tell the user if there are errors
    this.reportValidity();
  }
}
