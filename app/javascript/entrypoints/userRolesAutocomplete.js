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

function addNewUser(uid, name) {
  const ul = document.querySelector('.selected-user-roles');
  const li = document.createElement('li');
  li.classList.add('selected-item');
  li.appendChild(document.createTextNode(`(${uid}) ${name}`));
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

// eslint-disable-next-line import/prefer-default-export
export function userRolesAutocomplete(usersLookupUrl) {
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
            `<option data-uid="${uid}" data-name="${userName}" value="(${uid}) ${cleanUserName}\xA0"></option>`,
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

  // Wire the textbox for data users to work as an autocomple textbox
  $('#user_find').on('input', (event) => {
    // When populating the dataList for the user list we add a non-breaking space (HTML &nbsp; HEX A0)
    // to each option. We use this special character here to detect when a user has selected an option
    // from the dataList (since no user will manually enter a non-breaking space).
    // This solution was grabbed from https://stackoverflow.com/a/74598110/16862920
    const value = event.currentTarget.value;
    const userSelectedValue = value.slice(-1) === '\xA0';
    if (userSelectedValue === true) {
      const userRoleList = document.getElementById('request-user-roles');
      const cleanValue = value.slice(0, -1);
      if (!userRoleList.value.includes(cleanValue)) {
        const elementSelected = $(`#princeton_users [value="${value}"]`);
        addNewUser(elementSelected.data('uid'), elementSelected.data('name'));
      }
      event.currentTarget.value = '';
    } else {
      // User is typing, fetch users that match the value entered so far
      debouncedSearch(value, "#princeton_users");
    }
  });

  // Wire the textbox for data sponsors to work as an autocomple textbox
  $('#request_data_sponsor').on('input', (event) => {
    const value = event.currentTarget.value;
    const userSelectedValue = value.slice(-1) === '\xA0';
    if (userSelectedValue === true) {
      const elementSelected = $(`#data_sponsors [value="${value}"]`);
      event.currentTarget.value = elementSelected.data('uid');
      event.preventDefault();
    } else {
      debouncedSearch(value, "#data_sponsors");
    }
  });

  $().on('keydown', (e) => { if (e.key === 'Enter') {
    console.log("prevented default");
    e.preventDefault();
  } });

  // Wire the textbox for data managers to work as an autocomple textbox
  $('#request_data_manager').on('input', (event) => {
    const value = event.currentTarget.value;
    const userSelectedValue = value.slice(-1) === '\xA0';
    if (userSelectedValue === true) {
      const elementSelected = $(`#data_managers [value="${value}"]`);
      event.currentTarget.value = elementSelected.data('uid');
    } else {
      debouncedSearch(value, "#data_managers");
    }
  });

  // Prevent the HTML form from being submitted when the user press enter
  // on these textboxes
  preventFormSubmit('#request_data_sponsor');
  preventFormSubmit('#request_data_manager');
  preventFormSubmit('#user_find');

  registerRemove();
}
