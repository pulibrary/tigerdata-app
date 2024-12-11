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
        case 'content':
          content.style.borderBottom = 'solid';
          content.style.borderColor = '#E77500';
          content.classList.add('active');
          break;
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
      // const tab = document.getElementById('tab-nav');

      if (!content.classList.contains('active')) {
        content.style.borderBottom = 'solid';
        content.style.borderColor = '#121212';
      }
    });

    $('#project-content').on('mouseleave', (el) => {
      const element = el;
      element.preventDefault();
      // const tab = document.getElementById('tab-nav');

      if (!content.classList.contains('active')) {
        content.style.border = 'none';
      }
    });

    $('#project-content').on('click', (el) => {
      const element = el;
      element.preventDefault();
      // const tab = document.getElementById('tab-nav');
      // change background color to red
      content.style.borderBottom = 'solid';
      content.style.borderColor = '#E77500';
      content.classList.add('active');
    });

    $('#project-details').on('mouseenter', (el) => {
      const element = el;
      element.preventDefault();
      // const tab = document.getElementById('tab-nav');

      if (!details.classList.contains('active')) {
        details.style.borderBottom = 'solid';
        details.style.borderColor = '#121212';
      }
    });

    $('#project-details').on('mouseleave', (el) => {
      const element = el;
      element.preventDefault();
      // const tab = document.getElementById('tab-nav');

      if (!details.classList.contains('active')) {
        details.style.border = 'none';
      }
    });

    $('#project-details').on('click', (el) => {
      const element = el;
      element.preventDefault();
      // const tab = document.getElementById('tab-nav');
      // change background color to red
      details.style.borderBottom = 'solid';
      details.style.borderColor = '#E77500';
      details.classList.add('active');
    });

    $('#project-script').on('mouseenter', (el) => {
      const element = el;
      element.preventDefault();
      // const tab = document.getElementById('tab-nav');

      if (!script.classList.contains('active')) {
        script.style.borderBottom = 'solid';
        script.style.borderColor = '#121212';
      }
    });

    $('#project-script').on('mouseleave', (el) => {
      const element = el;
      element.preventDefault();
      // const tab = document.getElementById('tab-nav');

      if (!script.classList.contains('active')) {
        script.style.border = 'none';
      }
    });

    $('#project-script').on('click', (el) => {
      const element = el;
      element.preventDefault();
      // const tab = document.getElementById('tab-nav');
      // change background color to red
      script.style.borderBottom = 'solid';
      script.style.borderColor = '#E77500';
      script.classList.add('active');
    });

    $('#project-approval').on('mouseenter', (el) => {
        const element = el;
        element.preventDefault();
        // const tab = document.getElementById('tab-nav');

        if (!approval.classList.contains('active')) {
          approval.style.borderBottom = 'solid';
          approval.style.borderColor = '#121212';
        }
      });

      $('#project-approval').on('mouseleave', (el) => {
        const element = el;
        element.preventDefault();
        // const tab = document.getElementById('tab-nav');

        if (!approval.classList.contains('active')) {
          approval.style.border = 'none';
        }
      });

      $('#project-approval').on('click', (el) => {
        const element = el;
        element.preventDefault();
        // const tab = document.getElementById('tab-nav');
        // change background color to red
        approval.style.borderBottom = 'solid';
        approval.style.borderColor = '#E77500';
        approval.classList.add('active');
      });
  }

  export function projectTab(id) {
    const projectID = id;
    $('#project-content').on('click', (inv) => {
      const element = inv;
      element.preventDefault();
      const content_location = window.location + '/contents';

      $.ajax({
        type: 'GET',
        url: content_location,
        success() { // on success..
          window.location.href = content_location; // update the DIV
        },
      });
    });

    $('#project-details').on('click', (inv) => {
      const element = inv;
      element.preventDefault();
      const base_url = window.location.href;
      const content = "/contents"
      const detail_location = base_url.replace(content, "");
      $.ajax({
        type: 'GET',
        url: detail_location,
        success() { // on success..
            window.location.href = detail_location; // update the DIV
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
