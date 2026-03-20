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
