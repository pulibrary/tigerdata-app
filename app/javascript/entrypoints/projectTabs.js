export function projectStyle(railsSession) {
  const content = document.getElementById('project-content');
  const details = document.getElementById('project-details');
  const script = document.getElementById('project-script');
  const approval = document.getElementById('project-approval');
  const session = railsSession;
  const project = document.getElementById('show') || document.getElementById('content');

  // Check the session to see which tab should start as active be active
  if (project) {
    switch (session) {
      case 'details':
        details.style.borderBottom = 'solid';
        details.style.borderColor = '#E77500';
        details.classList.add('active');
        break;
      case 'script':
        script.style.borderBottom = 'solid';
        script.style.borderColor = '#E77500';
        script.classList.add('active');
        break;
      case 'approval':
        approval.style.borderBottom = 'solid';
        approval.style.borderColor = '#E77500';
        approval.classList.add('active');
        break;
      default:
        content.style.borderBottom = 'solid';
        content.style.borderColor = '#E77500';
        content.classList.add('active');
        break;
    }
  }

  $('#project-content').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();
    if (!content.classList.contains('active')) {
      content.style.borderBottom = 'solid';
      content.style.borderColor = '#121212';
    }
  });

  $('#project-content').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();
    if (!content.classList.contains('active')) {
      content.style.border = 'none';
    }
  });

  $('#project-content').on('click', (el) => {
    const element = el;
    element.preventDefault();
    content.style.borderBottom = 'solid';
    content.style.borderColor = '#E77500';
    content.classList.add('active');
  });

  $('#project-details').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();
    if (!details.classList.contains('active')) {
      details.style.borderBottom = 'solid';
      details.style.borderColor = '#121212';
    }
  });

  $('#project-details').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();
    if (!details.classList.contains('active')) {
      details.style.border = 'none';
    }
  });

  $('#project-details').on('click', (el) => {
    const element = el;
    element.preventDefault();
    details.style.borderBottom = 'solid';
    details.style.borderColor = '#E77500';
    details.classList.add('active');
  });

  $('#project-script').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();
    if (!script.classList.contains('active')) {
      script.style.borderBottom = 'solid';
      script.style.borderColor = '#121212';
    }
  });

  $('#project-script').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();
    if (!script.classList.contains('active')) {
      script.style.border = 'none';
    }
  });

  //   $('#project-script').on('click', (el) => {
  //     const element = el;
  //     element.preventDefault();
  //     script.style.borderBottom = 'solid';
  //     script.style.borderColor = '#E77500';
  //     script.classList.add('active');
  //   });

  $('#project-approval').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();

    if (!approval.classList.contains('active')) {
      approval.style.borderBottom = 'solid';
      approval.style.borderColor = '#121212';
    }
  });

  $('#project-approval').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();

    if (!approval.classList.contains('active')) {
      approval.style.border = 'none';
    }
  });

//   $('#project-approval').on('click', (el) => {
//     const element = el;
//     element.preventDefault();
//     approval.style.borderBottom = 'solid';
//     approval.style.borderColor = '#E77500';
//     approval.classList.add('active');
//   });
}

export function projectTab() {
  $('#project-content').on('click', (inv) => {
    const element = inv;
    element.preventDefault();
    const contentLocation = `${window.location}/contents`;

    $.ajax({
      type: 'GET',
      url: contentLocation,
      success() { // on success..
        window.location.href = contentLocation; // update the DIV
      },
    });
  });

  $('#project-details').on('click', (inv) => {
    const element = inv;
    element.preventDefault();
    const baseURL = window.location.href;
    const content = '/contents';
    const detailLocation = baseURL.replace(content, '');
    $.ajax({
      type: 'GET',
      url: detailLocation,
      success() { // on success..
        window.location.href = detailLocation; // update the DIV
      },
    });
  });

  // $('#project-script').on('click', (inv) => {
  //   const element = inv;
  //   element.preventDefault();
  // });

  // $('#project-approval').on('click', (inv) => {
  //   const element = inv;
  //   element.preventDefault();
  // });
}