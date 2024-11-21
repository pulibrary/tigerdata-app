export function dashStyle(railsSession) {
  const classic = document.getElementById('dash-classic');
  const project = document.getElementById('dash-project');
  const activity = document.getElementById('dash-activity');
  const admin = document.getElementById('dash-admin');
  const session = railsSession;
  const home = document.getElementById('welcome');

  // Check the session to see which tab should start as active be active
  if (home) {
    switch (session) {
      case 'classic':
        classic.style.borderBottom = 'solid';
        classic.style.borderColor = '#E77500';
        classic.classList.add('active');
        break;
      case 'project':
        project.style.borderBottom = 'solid';
        project.style.borderColor = '#E77500';
        project.classList.add('active');
        break;
      case 'activity':
        activity.style.borderBottom = 'solid';
        activity.style.borderColor = '#E77500';
        activity.classList.add('active');
        break;
      case 'admin':
        admin.style.borderBottom = 'solid';
        admin.style.borderColor = '#E77500';
        admin.classList.add('active');
        break;
      default:
        classic.style.borderBottom = 'solid';
        classic.style.borderColor = '#E77500';
        classic.classList.add('active');
        break;
    }
  }

  $('#dash-classic').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!classic.classList.contains('active')) {
      classic.style.borderBottom = 'solid';
      classic.style.borderColor = '#121212';
    }
  });

  $('#dash-classic').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!classic.classList.contains('active')) {
      classic.style.border = 'none';
    }
  });

  $('#dash-classic').on('click', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');
    // change background color to red
    classic.style.borderBottom = 'solid';
    classic.style.borderColor = '#E77500';
    classic.classList.add('active');
  });

  $('#dash-project').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!project.classList.contains('active')) {
      project.style.borderBottom = 'solid';
      project.style.borderColor = '#121212';
    }
  });

  $('#dash-project').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!project.classList.contains('active')) {
      project.style.border = 'none';
    }
  });

  $('#dash-project').on('click', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');
    // change background color to red
    project.style.borderBottom = 'solid';
    project.style.borderColor = '#E77500';
    project.classList.add('active');
  });

  $('#dash-activity').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!activity.classList.contains('active')) {
      activity.style.borderBottom = 'solid';
      activity.style.borderColor = '#121212';
    }
  });

  $('#dash-activity').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');

    if (!activity.classList.contains('active')) {
      activity.style.border = 'none';
    }
  });

  $('#dash-activity').on('click', (el) => {
    const element = el;
    element.preventDefault();
    // const tab = document.getElementById('tab-nav');
    // change background color to red
    activity.style.borderBottom = 'solid';
    activity.style.borderColor = '#E77500';
    activity.classList.add('active');
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
  const url = window.location.href;
  $('#dash-classic').on('click', (inv) => {
    const element = inv;
    element.preventDefault();
    $.ajax({
      type: 'POST',
      url: `${url}dash_classic`,
      data: { dashtab: 'classic' },
      success() { // on success..
        window.location = url; // update the DIV
      },
    });
  });

  $('#dash-project').on('click', (inv) => {
    const element = inv;
    element.preventDefault();
    $.ajax({
      type: 'POST',
      url: `${url}dash_project`,
      data: { dashtab: 'project' },
      success() { // on success..
        window.location.reload(); // update the DIV
      },
    });
  });

  $('#dash-activity').on('click', (inv) => {
    const element = inv;
    element.preventDefault();
    $.ajax({
      type: 'POST',
      url: `${url}dash_activity`,
      data: { dashtab: 'activity' },
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
      url: `${url}dash_admin`,
      data: { dashtab: 'admin' },
      success() { // on success..
        window.location.reload(); // update the DIV
      },
    });
  });
}
