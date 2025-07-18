// import 'bootstrap/js/src/alert'
// import 'bootstrap/js/src/button'
// import 'bootstrap/js/src/carousel'
import 'bootstrap/js/src/collapse';
import 'bootstrap/js/src/dropdown';
// import 'bootstrap/js/src/modal'
// import 'bootstrap/js/src/popover'
import 'bootstrap/js/src/scrollspy';
// import 'bootstrap/js/src/tab'
// import 'bootstrap/js/src/toast'
// import 'bootstrap/js/src/tooltip'

import * as bootstrap from 'bootstrap';

// ActionCable Channels
import '../channels';

import { setTargetHtml } from './helper';
import { displayMediafluxVersion } from './mediafluxVersion';
import { showCreateScript } from './atermScripts';
import { dashStyle, dashTab } from './dashboardTabs';
import { departmentAutocomplete } from './departmentAutocomplete';
import { setupTable } from './pulDataTables';
import { showMoreLess } from './showMoreLess';
import { projectStyle, projectTab } from './projectTabs';
import { userRolesAutocomplete } from './userRolesAutocomplete';
import { storageInputs } from './storageInputs';
import { validationClear } from './validation';

window.bootstrap = bootstrap;
window.displayMediafluxVersion = displayMediafluxVersion;
window.showCreateScript = showCreateScript;
window.dashStyle = dashStyle;
window.dashTab = dashTab;
window.setupTable = setupTable;
window.showMoreLess = showMoreLess;
window.projectStyle = projectStyle;
window.projectTab = projectTab;

async function fetchListContents(listContentsPath) {
  const response = await fetch(listContentsPath);

  return response.json();
}

function initListContentsModal() {
  const listContentsModal = document.getElementById('list-contents-modal');
  if (listContentsModal) {
    const requestListContents = document.getElementById('request-list-contents');
    if (requestListContents) {
      const listContentsPath = requestListContents.attributes['data-list-contents-path'];

      requestListContents.addEventListener('click', () => {
        const listContentsPromise = fetchListContents(listContentsPath.value);
        listContentsPromise.then((response) => {
          const $alert = document.getElementById('project-alert');
          if ($alert) {
            $alert.textContent = response.message;
            $alert.classList.remove('d-none');

            const modal = bootstrap.Modal.getInstance(listContentsModal);
            modal.hide();
          }
        });
      });
    }
  }
}

// delete these two functions when new dashboard is fully implemented
function showMoreLessContent() {
  $('#show-more').on('click', (el) => {
    const element = el;
    if (el.target.textContent === 'Show More') {
      $('#file-list>tbody>tr.bottom-section').removeClass('invisible-row');
      element.target.textContent = 'Show Less';
    } else {
      // Show less
      $('#file-list>tbody>tr.bottom-section').addClass('invisible-row');
      element.target.textContent = 'Show More';
      // Source: https://stackoverflow.com/a/10681265/446681
      $(window).scrollTop(0);
    }
    el.preventDefault();
  });
}

function showMoreLessSysAdmin() {
  $('#show-more-sysadmin').on('click', (el) => {
    const element = el;
    if (el.target.textContent === 'Show More') {
      $('.bottom-section').removeClass('invisible-row');
      element.target.textContent = 'Show Less';
    } else {
      // Show less
      $('.bottom-section').addClass('invisible-row');
      element.target.textContent = 'Show More';
      // Source: https://stackoverflow.com/a/10681265/446681
    }
    el.preventDefault();
  });
}

function emulate() {
  $(document).ready(() => {
    $("[name='emulation_menu']").on('change', () => {
      $.ajax({
        type: 'POST',
        url: $('#emulation-form').attr('action'),
        data: $('#emulation-form').serialize(),
        success() {
          // on success..
          window.location.reload(); // update the DIV
        },
      });
    });
  });
}

function showValidationError() {
  const sponsor = document.getElementById('sponsor_error');
  const manager = document.getElementById('manager_error');
  const title = document.getElementById('title_error');
  const directory = document.getElementById('directory_error');

  $('#data_sponsor').on('invalid', (inv) => {
    const element = inv;
    element.preventDefault();
    // sponsor.style.display += '-webkit-inline-box', 'block';
    // add webkit inline box and block to the sponsor style display in two separate lines
    sponsor.style.display += '-webkit-inline-box';
    sponsor.style.display += 'block';
  });

  $('#data_manager').on('invalid', (inv) => {
    const element = inv;
    element.preventDefault();
    manager.style.display += '-webkit-inline-box';
    manager.style.display += 'block';
  });

  $('#title').on('change', (inv) => {
    const element = inv;
    element.preventDefault();
    if (element.target.value === '') {
      title.style.display += '-webkit-inline-box';
      title.style.display += 'block';
    }
  });

  $('#project_directory').on('change', (inv) => {
    const element = inv;
    element.preventDefault();
    if (element.target.value === '') {
      directory.style.display += '-webkit-inline-box';
      directory.style.display += 'block';
    }
  });
}

function charCount() {
  $('.counted-input').on('keyup', (event) => {
    const element = event.currentTarget;
    element.parentNode.querySelector('.current-count').innerHTML =
      `${element.value.length}/${element.maxLength} characters`;
  });
}

function initPage() {
  $('#test-jquery').click((event) => {
    setTargetHtml(event, 'jQuery works!');
  });
  initListContentsModal();
  showMoreLessContent();
  showMoreLessSysAdmin();
  emulate();
  showValidationError();
  charCount();
  storageInputs();
  departmentAutocomplete();
  userRolesAutocomplete();
  validationClear();
}

window.addEventListener('load', () => initPage());
window.addEventListener('turbo:render', () => initPage());
