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

function addNewUser(value, uid) {
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
  input.value = JSON.stringify({ uid: uid, name: value });
  input.name = 'request[user_roles][]';
  li.appendChild(input);
  ul.appendChild(li);
  registerRemove();
}

// eslint-disable-next-line import/prefer-default-export
export function userRolesAutocomplete(usersLookupUrl) {
  $('#user_find').on('input', (event) => {
    // When populating the dataList for the user list we add a non-breaking space (HTML &nbsp; HEX A0)
    // to each option. We use this special character here to detect when a user has selected an option
    // from the dataList (since no user will manually enter a non-breaking space).
    // This solution was grabbed from https://stackoverflow.com/a/74598110/16862920
    const { value } = event.currentTarget;
    if (value.slice(-1) === '\xA0') {
      const userRoleList = document.getElementById('request-user-roles');
      const cleanValue = value.slice(0, -1);
      if (!userRoleList.value.includes(cleanValue)) {
        addNewUser(cleanValue, $(`#princeton_users [value="${value}"]`).data('uid'));
      }
      const current = event.currentTarget;
      current.value = '';
    } else {
      $.ajax({
        url: `${usersLookupUrl}?query=${value}`,
        success: function (result) {
          // Clear the current list of values in the dataList...
          var dataList = $('#princeton_users');
          dataList.empty();
          // ...and repopulate the dataList with the results from the AJAX call
          for (var i = 0; i < result.suggestions.length; i += 1) {
            var uid = result.suggestions[i].data;
            var userName = result.suggestions[i].value;
            // ...the non-breaking space character (hex A0) is used to mark
            // values coming from the datalist (see userRolesAutocomplete)
            dataList.append(
              `<option data-uid='${uid}' value=" (${uid}) ${userName}\xA0"></option>`,
            );
          }
        },
      });
    }
  });

  registerRemove();
}
