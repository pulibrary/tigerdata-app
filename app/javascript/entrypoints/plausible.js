import plausible from 'plausible-tracker';
function logPlausibleNewProject() {
  plausible('New Project Request');
}

export default logPlausibleNewProject;