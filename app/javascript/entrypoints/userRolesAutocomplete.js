function removeUserRoleInTable(event) {
  const row = event.currentTarget.parentElement.parentElement.parentElement;
  row.remove();
}

function removeUserRole(event) {
  const li = event.currentTarget.parentElement;
  li.remove();
}

function removeNoDataUser(event) {
  const row = event.currentTarget.parentElement;
  row.remove();
}

function addNoDataUser(event) {
  const table = event.currentTarget;
  if (table.getElementsByClassName('row').length === 1) {
    const row = document.createElement('div');
    row.classList.add('row');

    const noUser = document.createElement('div');
    noUser.classList.add('no-users');
    row.appendChild(noUser);

    const content = document.createElement('div');
    content.classList.add('content');
    noUser.appendChild(content);

    const noDataUser = document.createElement('div');
    noDataUser.classList.add('no-users-text');
    content.appendChild(noDataUser);

    noDataUser.appendChild(document.createTextNode('No Data User(s) added'));
    table.appendChild(row);
  }
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

  $('.remove-user-role-in-table').click((event) => {
    removeUserRoleInTable(event);
    addNoDataUser({ currentTarget: document.querySelector('.user-table') });
  });

  $('.remove-user-role-in-table').on('input', (event) => {
    removeUserRoleInTable(event);
  });

  $('.remove-user-role-in-table').keyup((event) => {
    if (event.keyCode === 13) removeUserRoleInTable(event);
  });
}

function addNewUser(uid, name) {
  const ul = document.querySelector('.selected-user-roles');
  const li = document.createElement('li');
  li.classList.add('selected-item');
  li.appendChild(document.createTextNode(name));
  const newDiv = document.createElement('div');
  newDiv.classList.add('remove-user-role');
  newDiv.classList.add('remove-item');
  newDiv.focus = true;
  newDiv.tabIndex = 0;
  li.appendChild(newDiv);
  const input = document.createElement('input');
  input.type = 'hidden';
  input.value = JSON.stringify({ uid, name });
  input.name = 'request[user_roles][]';
  li.appendChild(input);
  ul.appendChild(li);
  registerRemove();
}

function newCell(content) {
  const cell = document.createElement('div');
  cell.classList.add('cell');
  const newCellContent = document.createElement('div');
  newCellContent.classList.add('content');
  cell.appendChild(newCellContent);
  newCellContent.appendChild(content);
  return cell;
}

function newRadio(name, checked, value) {
  let radioHtml = `<input type="radio" name="${name}" value="${value}"`;
  if (checked) {
    radioHtml += ' checked="checked"';
  }
  radioHtml += '/>';

  const radioFragment = document.createElement('div');
  radioFragment.innerHTML = radioHtml;

  return radioFragment.firstChild;
}

function newRemove() {
  const newRemoveDiv = document.createElement('div');
  newRemoveDiv.classList.add('remove-user-role-in-table');
  newRemoveDiv.classList.add('remove-item');
  newRemoveDiv.focus = true;
  newRemoveDiv.tabIndex = 0;
  return newRemoveDiv;
}

function newTableRow(table, input) {
  const json = JSON.parse(input.value);
  const newRow = document.createElement('div');
  newRow.classList.add('row');
  const newName = newCell(document.createTextNode(json.name));
  newName.classList.add('user-cell');
  newRow.appendChild(newName);
  const roCell = newCell(newRadio(`request[read_only_${json.uid}]`, true, 'true'));
  newRow.appendChild(roCell);
  const rwCell = newCell(newRadio(`request[read_only_${json.uid}]`, false, 'false'));
  newRow.appendChild(rwCell);
  const removeCell = newCell(newRemove());
  newRow.appendChild(removeCell);
  newRow.appendChild(input);
  table.appendChild(newRow);
}

function moveNewUsers() {
  const ul = document.querySelector('.selected-user-roles');
  const table = document.querySelector('.user-table');
  const items = ul.getElementsByTagName('li');
  for (let i = 0; i < items.length; i += 1) {
    // do something with items[i], which is a <li> element
    newTableRow(table, items[i].getElementsByTagName('input')[0]);
  }
  ul.replaceChildren();
  registerRemove();
  removeNoDataUser({ currentTarget: document.querySelector('.no-users') });
}

// eslint-disable-next-line import/prefer-default-export
export function userRolesAutocomplete() {
  const usersLookupUrl = document.querySelector('#users_lookup_url').value;
  // Debounce is used to limit the number of times a function is called in a short period of time.
  // source: https://github.com/jrrio/datalist-autocomplete-ajax/blob/main/main.js#L159C3-L166C5
  // see also: https://www.geeksforgeeks.org/javascript/debouncing-in-javascript/
  const debounce = (func, delay = 250) => {
    let timeout;
    return (...args) => {
      clearTimeout(timeout);
      timeout = setTimeout(() => {
        func.apply(this, args);
      }, delay);
    };
  };

  // source: https://dev.to/ibrahimalanshor/how-to-prevent-enter-from-submitting-a-form-input-with-javascript-4j4n
  const preventFormSubmit = (elementId) => {
    $(elementId).on('keydown', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault();
      }
    });
  };

  // Performs a user lookup via AJAX, the results are
  // used to populate the indicated datalist
  const search = (searchValue, datalistId) => {
    $.ajax({
      url: `${usersLookupUrl}?query=${searchValue}`,
      success: (result) => {
        // Re-populate the dataList with the results from the AJAX call
        const dataList = $(datalistId);
        dataList.empty();
        for (let i = 0; i < result.suggestions.length; i += 1) {
          const uid = result.suggestions[i].data;
          const userName = result.suggestions[i].value;
          // remove punctuation from the value displayed in the datalist so that
          // matches can be made without having to be super exact (makes the search
          // more forgiving in FireFox)
          const cleanUserName = userName.replace(/[,.]/g, ' ').replace(/\s\s/g, ' ');
          dataList.append(
            `<option data-uid="${uid}" data-name="${userName}" value="${cleanUserName}\xA0"></option>`,
          );
        }
      },
    });
  };

  // Wraps the search function so that it is not called too frequently
  // if the user types the search value quickly. For example if the user
  // enters "abc" quickly we call the search once with "abc" rather than
  // three times ("a", then "ab", and then "abc").
  const debouncedSearch = debounce(search);

  function handleUserInput(element, event) {
    const { value } = event.currentTarget;
    const userSelectedValue = value.slice(-1) === '\xA0';
    if (userSelectedValue === true) {
      const elementSelected = $(`${element} [value="${value}"]`);
      const current = event.currentTarget;
      const currentHidden = $(`#${current.id}_uid`)[0];
      current.value = elementSelected.data('name');
      currentHidden.value = elementSelected.data('uid');
      event.preventDefault();
    } else {
      debouncedSearch(value, element);
    }
  }

  // Wire the textbox for data users to work as an autocomple textbox
  $('#user_find').on('input', (event) => {
    // When populating the dataList for the user list we add a non-breaking space (HTML &nbsp; HEX A0)
    // to each option. We use this special character here to detect when a user has selected an option
    // from the dataList (since no user will manually enter a non-breaking space).
    // This solution was grabbed from https://stackoverflow.com/a/74598110/16862920
    const { value } = event.currentTarget;
    const userSelectedValue = value.slice(-1) === '\xA0';
    if (userSelectedValue === true) {
      const userRoleList = document.getElementById('request-user-roles');
      const cleanValue = value.slice(0, -1);
      if (!userRoleList.value.includes(cleanValue)) {
        const elementSelected = $(`#princeton_users [value="${value}"]`);
        addNewUser(elementSelected.data('uid'), elementSelected.data('name'));
      }
      const current = event.currentTarget;
      current.value = '';
    } else {
      // User is typing, fetch users that match the value entered so far
      debouncedSearch(value, '#princeton_users');
    }
  });

  // Wire the textbox for data sponsors to work as an autocomple textbox
  $('#request_data_sponsor').on('input', (event) => {
    handleUserInput('#data_sponsors', event);
  });

  // Wire the textbox for data managers to work as an autocomple textbox
  $('#request_data_manager').on('input', (event) => {
    handleUserInput('#data_managers', event);
  });

  // Prevent the HTML form from being submitted when the user press enter
  // on these textboxes
  preventFormSubmit('#request_data_sponsor');
  preventFormSubmit('#request_data_manager');
  preventFormSubmit('#user_find');

  registerRemove();

  $('#user-role').on('beforetoggle', (event) => {
    if (event.originalEvent.newState === 'open') {
      // set focus here
    } else {
      moveNewUsers();
    }
  });
}
