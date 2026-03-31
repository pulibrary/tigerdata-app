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

function checkStoragePopoverFields() {
  const storageAmount = document.getElementById('storage_amount').value;
  const storageUnit = document.getElementById('storage_unit').value;
  const storageJustification = document.getElementById('storage_justification').value;
  const growthExpectation = document.getElementById('storage_growth_expectation').value;
  const dateNeeded = document.getElementById('storage_date_needed').value;
  const errorMessages = document.getElementsByClassName('storage-modal-error');
  const fields = [
    storageAmount,
    storageUnit,
    storageJustification,
    growthExpectation,
    dateNeeded,
  ];

  // check that all fields are filled out before allowing the popover to close
  for (let i = 0; i < fields.length; i += 1) {
    if (fields[i].trim().length === 0 || !fields[i]) {
      if (i === 0) {
        errorMessages[0].hidden = false; // eslint-disable-line no-param-reassign
        continue; // eslint-disable-line no-continue
      } else if (i === 4) {
        errorMessages[i - 1].hidden = false; // eslint-disable-line no-param-reassign
        return false;
      } else {
        errorMessages[i - 1].hidden = false; // eslint-disable-line no-param-reassign
        continue; // eslint-disable-line no-continue
      }
    }
    if (i === 4 && fields[i].trim().length !== 0) {
      const messages = Array.from(errorMessages);
      const errorsDisplayed = messages.some((el) => el.checkVisibility());
      if (errorsDisplayed) {
        return false;
      } 
        return true;
      
    }
  }
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
