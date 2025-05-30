function removeUserRole(event) {
  const li = event.currentTarget.parentElement;
  li.remove();
}

function registerRemove() {
  $('.remove-user-role').on('input', (event) => {
    removeUserRole(event);
  });

  $('.remove-user-role').keyup((event) => {
    if (event.keyCode === 13) removeUserRole(event);
  });

  $('.remove-user-role').click((event) => {
    removeUserRole(event);
  });
}

function addNewUser(value, dataValue) {
  const ul = document.querySelector('.selected-user-roles');
  const li = document.createElement('li');
  li.classList.add('selected-item');
  li.appendChild(document.createTextNode(value));
  const newDiv = document.createElement('div');
  newDiv.classList.add('remove-user-role');
  newDiv.classList.add('remove-item');
  newDiv.focus = true;
  newDiv.tabIndex = 0;
  li.appendChild(newDiv);
  const input = document.createElement('input');
  input.type = 'hidden';
  input.value = JSON.stringify(dataValue);
  input.name = 'request[user_roles][]';
  li.appendChild(input);
  ul.appendChild(li);
  registerRemove();
}

// eslint-disable-next-line import/prefer-default-export
export function userRolesAutocomplete() {
  $('#user_find').on('input', (event) => {
    // We add a non-breaking back space to each option to see when a option has been entered into the text input as
    //  no user would type a &nbsp; into the input.  When the HTML5 option is selected we can see clearly that it has;
    //  This solution was grabbed from https://stackoverflow.com/a/74598110/16862920
    const { value } = event.currentTarget;
    if (value.slice(-1) === '\xa0') {
      const userRoleList = document.getElementById('request-user-roles');
      const cleanValue = value.slice(0, -1);
      if (!userRoleList.value.includes(cleanValue))
        addNewUser(cleanValue, $(`#princeton_users [value="${value}"]`).data('value'));
      const current = event.currentTarget;
      current.value = '';
    }
  });

  registerRemove();
}
