export function dashStyle(railsSession) {
  const project = document.getElementById('dash-projects');
  const admin = document.getElementById('dash-admin');
  const requests = document.getElementById('dash-requests');
  const session = railsSession;
  const home = document.getElementById('welcome');

  // Check the session to see which tab should start as active be active
  if (home) {
    switch (session) {
      case 'project':
        project.style.borderBottom = 'solid';
        project.style.borderColor = '#E77500';
        project.classList.add('active');
        break;
      case 'admin':
        admin.style.borderBottom = 'solid';
        admin.style.borderColor = '#E77500';
        admin.classList.add('active');
        break;
      case 'requests':
        requests.style.borderBottom = 'solid';
        requests.style.borderColor = '#E77500';
        requests.classList.add('active');
        break;
      default:
        if (project !== null) {
          project.style.borderBottom = 'solid';
          project.style.borderColor = '#E77500';
          project.classList.add('active');
        }
        break;
    }
  }

  function styleTab(tabId, tabElement) {
    const tabEl = tabElement;

    $(tabId).on('mouseenter', (el) => {
      el.preventDefault();
      if (!tabEl.classList.contains('active')) {
        tabEl.style.borderBottom = 'solid';
        tabEl.style.borderColor = '#121212';
      }
    });

    $(tabId).on('mouseleave', (el) => {
      el.preventDefault();
      if (!tabEl.classList.contains('active')) {
        tabEl.style.border = 'none';
      }
    });

    $(tabId).on('click', (el) => {
      el.preventDefault();
      tabEl.style.borderBottom = 'solid';
      tabEl.style.borderColor = '#E77500';
      tabEl.classList.add('active');
    });
  }

  styleTab('#dash-projects', project);
  styleTab('#dash-admin', admin);
  styleTab('#dash-requests', requests);
}

export function dashTab() {
  function setupTab(tabId, tabUrl, tabName) {
    $(tabId).on('click', (element) => {
      element.preventDefault();

      let headers = {};
      const tokenElements = document.getElementsByName('csrf-token');
      if (tokenElements[0]) {
        headers = { 'X-CSRF-Token': tokenElements[0].content };
      }

      $.ajax({
        type: 'POST',

        url: tabUrl,
        data: { dashtab: tabName },
        headers,
        success() {
          // on success..
          window.location.reload(); // update the DIV
        },
      });
    });
  }

  setupTab('#dash-projects', '/dash_project', 'project');
  setupTab('#dash-admin', '/dash_admin', 'admin');
  setupTab('#dash-requests', '/dash_requests', 'requests');
}
