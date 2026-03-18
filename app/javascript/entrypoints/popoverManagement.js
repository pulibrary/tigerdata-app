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
  const switchGlobusPopover = document.getElementById('globus-switch');
  if (switchGlobusPopover !== null) {
    const globusAccessPopover = document.getElementById('globus-access');
    const projectId = window.location.href.split('/')[4]; // Extract project ID from URL, assuming URL structure is consistent
    switchGlobusPopover.addEventListener('click', () => {
      globusAccessPopover.hidePopover();
      triggerMailer(projectId);
    });
  }
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

  for (let i = 0; i < fields.length; i += 1) {
    if (fields[i].trim().length === 0 || !fields[i]) {
      errorMessage.forEach((message) => {
        message.hidden = false; // eslint-disable-line no-param-reassign
      });
      return false;
    }
  }
  return true;
}
export function requestMoreStoragePopoverManagement() {
  const requestMoreStoragePopover = document.getElementById('request-more-storage');
  const submitStorageRequestPopover = document.getElementById('submit-storage-request');
  const cancelStorageRequestPopover = document.getElementById('cancel-storage-request');
  const storageDetail = document.getElementById('storage-details');

  // hide the storage detail when the user opens more storage modal
  const requestMoreStorageModal = document.getElementsByClassName('request-more-storage-modal');
  for (let i = 0; i < requestMoreStorageModal.length; i += 1) {
    requestMoreStorageModal[i].addEventListener('beforetoggle', (event) => {
      if (event.newState === 'open') {
        storageDetail.hidePopover();
      } else {
        // clear the error message when the popover is closed
        const errorMessage = document.querySelectorAll('.storage-modal-error');
        errorMessage.forEach((message) => {
          message.hidden = true; // eslint-disable-line no-param-reassign
        });
      }
    });
  }

  submitStorageRequestPopover.addEventListener('click', () => {
    if (checkStoragePopoverFields()) {
      // TODO: submit the form and trigger the mailer, and then close the popover
      requestMoreStoragePopover.hidePopover();
    }
  });

  cancelStorageRequestPopover.addEventListener('click', () => {
    storageDetail.showPopover();
  });
}
