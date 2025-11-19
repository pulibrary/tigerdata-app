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

function newInput(json) {
  const input = document.createElement('input');
  input.type = 'hidden';
  input.value = JSON.stringify({ uid: json.id, name: json.label });
  input.name = 'request[user_roles][]';
  return input;
}

function newTableRow(table, json) {
  const newRow = document.createElement('div');
  newRow.classList.add('row');
  const newName = newCell(document.createTextNode(json.label));
  newName.classList.add('user-cell');
  newRow.appendChild(newName);
  const roCell = newCell(newRadio(`request[read_only_${json.id}]`, true, 'true'));
  newRow.appendChild(roCell);
  const rwCell = newCell(newRadio(`request[read_only_${json.id}]`, false, 'false'));
  newRow.appendChild(rwCell);
  const removeCell = newCell(newRemove());
  newRow.appendChild(removeCell);
  const input = newInput(json);
  newRow.appendChild(input);
  table.appendChild(newRow);
}

function moveNewUsers() {
  const newUsers = JSON.parse($('.all_selected')[0].value);
  const ul = document.querySelector('.modal-content .selected-items');
  const table = document.querySelector('.user-table');
  const items = ul.getElementsByTagName('li');
  for (let i = 0; i < newUsers.length; i += 1) {
    newTableRow(table, newUsers[i]);
    items[i].lastChild.click();
  }
  registerRemove();
  if (newUsers.length > 0)
    removeNoDataUser({ currentTarget: document.querySelector('.no-users') });
}

// eslint-disable-next-line import/prefer-default-export
export function userRolesAutocomplete() {
  registerRemove();

  $('#user-role').on('beforetoggle', (event) => {
    if (event.originalEvent.newState === 'open') {
      // set focus here
    } else {
      moveNewUsers();
    }
  });
}
