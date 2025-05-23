function removeDepartment(event) {
  const li = event.currentTarget.parentElement;
  const departmentList = document.getElementById('request-departments');
  departmentList.value = departmentList.value.replace(`${li.textContent}`, '');
  li.remove();
}

function registerRemove() {
  $('.remove-department').on('input', (event) => {
    removeDepartment(event);
  });

  $('.remove-department').keyup((event) => {
    if (event.keyCode === 13) removeDepartment(event);
  });
}

// eslint-disable-next-line import/prefer-default-export
export function departmentAutocomplete() {
  $('.datalist').on('input', (event) => {
    if (
      String(event.originalEvent.inputType) === 'insertReplacementText' ||
      event.originalEvent.inputType == null
    ) {
      const ul = document.querySelector('.selected-departments');
      const li = document.createElement('li');
      const departmentList = document.getElementById('request-departments');
      li.classList.add('selected-department');
      li.appendChild(document.createTextNode(event.currentTarget.value));
      const newDiv = document.createElement('div');
      newDiv.classList.add('remove-department');
      newDiv.focus = true;
      newDiv.tabIndex = 0;
      li.appendChild(newDiv);
      ul.appendChild(li);
      departmentList.value = `${departmentList.value},${event.currentTarget.value}`;
      registerRemove();
      const current = event.currentTarget;
      current.value = '';
    }
  });

  registerRemove();
}
