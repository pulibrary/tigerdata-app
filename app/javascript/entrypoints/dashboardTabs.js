export function dashStyle(railsSession) {
  const project = document.getElementById('dash-projects');
  const admin = document.getElementById('dash-admin');
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
      default:
        project.style.borderBottom = 'solid';
        project.style.borderColor = '#E77500';
        project.classList.add('active');
        break;
    }
  }

  $('#dash-projects').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!project.classList.contains('active')) {
      project.style.borderBottom = 'solid';
      project.style.borderColor = '#121212';
    }
  });

  $('#dash-projects').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!project.classList.contains('active')) {
      project.style.border = 'none';
    }
  });

  $('#dash-projects').on('click', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');
    // change background color to red
    project.style.borderBottom = 'solid';
    project.style.borderColor = '#E77500';
    project.classList.add('active');
  });

  $('#dash-admin').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!admin.classList.contains('active')) {
      admin.style.borderBottom = 'solid';
      admin.style.borderColor = '#121212';
    }
  });

  $('#dash-admin').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!admin.classList.contains('active')) {
      admin.style.border = 'none';
    }
  });

  $('#dash-admin').on('click', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');
    // change background color to red
    admin.style.borderBottom = 'solid';
    admin.style.borderColor = '#E77500';
    admin.classList.add('active');
  });
}

export function dashTab() {
  $('#dash-classic').on('click', (inv) => {
    const element = inv;
    element.preventDefault();
    $.ajax({
      type: 'POST',
      url: '/dash_classic',
      data: { dashtab: 'classic' },
      success() { // on success..
        window.location.reload(); // update the DIV
      },
    });
  });

  $('#dash-projects').on('click', (inv) => {
    const element = inv;
    element.preventDefault();
    $.ajax({
      type: 'POST',
      url: '/dash_project',
      data: { dashtab: 'project' },
      success() { // on success..
        window.location.reload(); // update the DIV
      },
    });
  });

  $('#dash-admin').on('click', (inv) => {
    const element = inv;
    element.preventDefault();
    $.ajax({
      type: 'POST',

      url: '/dash_admin',
      data: { dashtab: 'admin' },
      success() { // on success..
        window.location.reload(); // update the DIV
      },
    });
  });
}
