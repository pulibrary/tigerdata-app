import { sendGlobusRequest, sendStorageIncreaseRequest } from './mailers.js';
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

export function globusPopoverManagement() {
  const switchGlobusPopover = document.getElementById('globus-switch');
  if (switchGlobusPopover !== null) {
    const globusAccessPopover = document.getElementById('globus-access');
    const projectId = window.location.href.split('/')[4]; // Extract project ID from URL, assuming URL structure is consistent
    switchGlobusPopover.addEventListener('click', () => {
      globusAccessPopover.hidePopover();
      sendGlobusRequest(projectId);
    });
  }
}

function checkAndDisplayStorageFieldError(fieldId, errorFieldId) {
  const fieldValue = document.getElementById(fieldId).value;
  const errorField = document.getElementById(errorFieldId);
  if (fieldValue.trim().length === 0 || !fieldValue) {
    errorField.hidden = false;
    return true; // There was an Error
  }
  return false; // No Error
}

function checkStoragePopoverFields() {
  const amountError = checkAndDisplayStorageFieldError(
    'storage_amount',
    'storage_amount_error',
  );
  const unitError = checkAndDisplayStorageFieldError('storage_unit', 'storage_amount_error');
  const justificationError = checkAndDisplayStorageFieldError(
    'storage_justification',
    'storage_justification_error',
  );
  const growthError = checkAndDisplayStorageFieldError(
    'storage_growth_expectation',
    'storage_growth_expectation_error',
  );
  const dateError = checkAndDisplayStorageFieldError(
    'storage_date_needed',
    'storage_date_needed_error',
  );
  if (amountError || unitError || justificationError || growthError || dateError) return false;
  return true;
}

export function storageIncreasePopoverManagement() {
  const requestMoreStoragePopover = document.getElementById('request-more-storage');
  const submitStorageRequestPopover = document.getElementById('submit-storage-request');
  const cancelStorageRequestPopover = document.getElementById('cancel-storage-request');
  const storageRequestConfirmationPopover = document.getElementById(
    'storage-request-confirmation',
  );
  const returnStorageOverview = document.getElementById('return-storage-overview');
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
    const storageAmount = document.getElementById('storage_amount').value;
    const storageUnit = document.getElementById('storage_unit').value;
    const requestedStorage = `${storageAmount} ${storageUnit}`;
    if (checkStoragePopoverFields()) {
      requestMoreStoragePopover.hidePopover();
      storageRequestConfirmationPopover.showPopover();
      sendStorageIncreaseRequest(
        window.location.href.split('/')[4], // Extract project ID from URL
        requestedStorage,
        document.getElementById('storage_justification').value,
        document.getElementById('storage_growth_expectation').value,
        document.getElementById('storage_date_needed').value,
      );
    }
  });

  cancelStorageRequestPopover.addEventListener('click', () => {
    storageDetail.showPopover();
  });

  returnStorageOverview.addEventListener('click', () => {
    storageDetail.showPopover();
  });
}
