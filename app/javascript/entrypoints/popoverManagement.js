// eslint-disable-next-line import/prefer-default-export
export function popoverManagement() {
  const popover = document.getElementById('confirm-delete-draft');
  if (popover === null) {
    return;
  }
  if (popover.attributes.data.value === 'auto-load') popover.showPopover();
  const deleteElements = document.getElementsByClassName('delete-confirm');

  //   hide the list if when the cancel prompt opens
  for (let i = 0; i < deleteElements.length; i += 1) {
    deleteElements[i].addEventListener('beforetoggle', (event) => {
      const listPopover = document.getElementById('draft-request-list');
      if (event.newState === 'open') {
        listPopover.hidePopover();
      }
    });
  }

  //   Show the list if the user cancels
  const deleteCancelElements = document.getElementsByClassName('delete-cancel');
  for (let i = 0; i < deleteCancelElements.length; i += 1) {
    deleteCancelElements[i].addEventListener('click', () => {
      document.getElementById('draft-request-list').showPopover();
    });
  }
}

function triggerMailer(projectId) {
  // Perform an AJAX POST request to the Rails controller action
  fetch(`/projects/send_globus_access_request`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      // Include CSRF token for security (Rails requires this for POST requests)
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
    },
    body: JSON.stringify({ project_id: projectId }), // Send any necessary data, e.g., project ID
  }).catch((error) => {
    console.error('Error:', error);
    alert('An error occurred.');
  });
}

export function globusPopoverManagement() {
  const globusAccessPopover = document.getElementById('globus-access');
  const switchGlobusPopover = document.getElementById('globus-switch');
  const projectId = window.location.href.split('/')[4]; // Extract project ID from URL, assuming URL structure is consistent

  switchGlobusPopover.addEventListener('click', () => {
    globusAccessPopover.hidePopover();
    triggerMailer(projectId);
  });
}
function checkStoragePopoverFields() {
  const storageAmount = document.getElementById('storage_amount').value;
  const storageUnit = document.getElementById('storage_unit').value;
  const storageJustification = document.getElementById('storage_justification').value;
  const growthExpectation = document.getElementById('storage_growth_expectation').value;
  const fields = [storageAmount, storageUnit, storageJustification, growthExpectation];
  const errorMessage = document.querySelectorAll('.storage-modal-error');
  // TODO: add check for date needed once the date picker is added

  // check that all fields are filled out before allowing the popover to close
  fields.forEach((field) => {
    if (field.trim().length === 0 || !field) {
      errorMessage.forEach((message) => {
        message.hidden = false; // eslint-disable-line no-param-reassign
      });
      return false;
    }

    return true;
  });
}
export function requestMoreStoragePopoverManagement() {
  const requestMoreStoragePopover = document.getElementById('request-more-storage');
  const switchRequestMoreStoragePopover = document.getElementById('submit-storage-request');

  switchRequestMoreStoragePopover.addEventListener('click', () => {
    if (checkStoragePopoverFields()) {
      // TODO: submit the form and trigger the mailer, and then close the popover
      requestMoreStoragePopover.hidePopover();
    }
  });
}
