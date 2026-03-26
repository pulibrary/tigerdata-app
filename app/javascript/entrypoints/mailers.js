export function sendGlobusRequest(projectId) {
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

export function sendStorageIncreaseRequest(
  projectId,
  requestedCapacity,
  justification,
  growthExpectation,
  dateNeeded,
) {
  // Perform an AJAX POST request to the Rails controller action
  fetch(`/projects/send_storage_increase_request`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      // Include CSRF token for security (Rails requires this for POST requests)
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
    },
    body: JSON.stringify({
      project_id: projectId,
      requested_capacity: requestedCapacity,
      justification,
      growth_expectation: growthExpectation,
      date_needed: dateNeeded,
    }), // Send any necessary data, e.g., project ID
  }).catch((error) => {
    console.error('Error:', error);
    alert('An error occurred.');
  });
}
