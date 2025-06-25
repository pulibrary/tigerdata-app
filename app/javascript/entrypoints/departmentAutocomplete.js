function removeDepartment(event) {
  const li = event.currentTarget.parentElement;
  li.remove();
}

function registerRemove() {
  $('.remove-department').on('input', (event) => {
    removeDepartment(event);
  });

  $('.remove-department').keyup((event) => {
    if (event.keyCode === 13) removeDepartment(event);
  });

  $('.remove-user-role').click((event) => {
    removeDepartment(event);
  });
}

function addNewDepartment(value, dataValue) {
  const ul = document.querySelector('.selected-departments');
  const li = document.createElement('li');
  li.classList.add('selected-item');
  li.appendChild(document.createTextNode(value));
  const newDiv = document.createElement('div');
  newDiv.classList.add('remove-department');
  newDiv.classList.add('remove-item');
  newDiv.focus = true;
  newDiv.tabIndex = 0;
  newDiv.title = 'Remove department';
  li.appendChild(newDiv);
  const input = document.createElement('input');
  input.type = 'hidden';
  input.value = JSON.stringify(dataValue);
  input.name = 'request[departments][]';
  li.appendChild(input);
  ul.appendChild(li);
  registerRemove();
}

// eslint-disable-next-line import/prefer-default-export
export function departmentAutocomplete() {
  $('#department_find').on('input', (event) => {
    const current = event.currentTarget;
    const { value } = current;

    // We add a non-breaking back space to each option to see when a option has been entered into the text input as
    //  no user would type a &nbsp; into the input.  When the HTML5 option is selected we can see clearly that it has;
    //  This solution was grabbed from https://stackoverflow.com/a/74598110/16862920
    if (value.slice(-1) === '\xa0') {
      const cleanValue = value.slice(0, -1);
      addNewDepartment(
        cleanValue,
        $(`#princeton_departments [value="${value}"]`).data('value'),
      );
      current.value = '';
    }
  });

  registerRemove();
}
