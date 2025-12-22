import { createApp } from 'vue';
import 'lux-design-system/dist/style.css';
import { LuxBadge, LuxInputMultiselect, LuxInputAsyncSelect } from 'lux-design-system';

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

// import * as bootstrap from 'bootstrap'; // avoid importing barrel file to reduce bundle size
import { Modal } from 'bootstrap';

// ActionCable Channels
import '../channels/index.js';
import '../channels/consumer.js';

import { setTargetHtml } from './helper.js';
import { displayMediafluxVersion } from './mediafluxVersion.js';
import { dashStyle, dashTab } from './dashboardTabs.js';
import { departmentAutocomplete } from './departmentAutocomplete.js';
import { setupTable } from './pulDataTables.js';
import { showMoreLess } from './showMoreLess.js';
import { projectStyle, projectTab } from './projectTabs.js';
import { userRolesAutocomplete } from './userRolesAutocomplete.js';
import { storageInputs } from './storageInputs.js';
import { validationClear } from './validation.js';
import { titleCopySaveExit } from './titleCopySaveExit.js';
import { copyPastePath } from './copyPastePath.js';
import { wizardNavigation } from './wizardNavigation.js';

const app = createApp({});

async function searchUsers(query) {
  if (query.length === 0) return null;
  if ($('#users_lookup_url').length === 0) return null;
  const userUrl = $('#users_lookup_url')[0].value;
  const result = await fetch(`${userUrl}?query=${query}`);
  const json = await result.json();
  if (json.suggestions) {
    return json.suggestions.map((user) => ({ label: user.value, id: user.data }));
  }
  return [];
}

function clearUserError(event, component) {
  document.getElementById(component).innerHTML = '';
}

// If you are not running a full Vue application, just embedding the component into a static HTML,
// ruby web app, or similar: one way to bind your logic to the async-load-items-function prop is
// to add it to the vue application's globalProperties.
const createMyApp = () => {
  const myapp = createApp(app);
  myapp.config.globalProperties.searchUsers = (query) => searchUsers(query);
  myapp.config.globalProperties.clearUserError = (event, component) =>
    clearUserError(event, component);
  return myapp;
};

document.addEventListener('DOMContentLoaded', () => {
  const elements = document.getElementsByClassName('lux');
  for (let i = 0; i < elements.length; i += 1) {
    createMyApp()
      .component('lux-badge', LuxBadge)
      .component('lux-input-multiselect', LuxInputMultiselect)
      .component('lux-input-async-select', LuxInputAsyncSelect)
      .mount(elements[i]);
  }
});

window.Modal = Modal;
window.displayMediafluxVersion = displayMediafluxVersion;
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

            const modal = Modal.getInstance(listContentsModal);
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

function descriptionValidation() {
  const descriptionCharLimit = $('#description').attr('character-limit');
  $('#description').on('keyup', (event) => {
    const element = event.currentTarget;
    element.parentNode.querySelector('#description-char-limit').innerHTML =
      `${element.value.length}/${descriptionCharLimit} characters`;
    if (element.value.length > descriptionCharLimit) {
      $('#description-char-limit').addClass('counted-input-error');
    } else if (element.value.length < descriptionCharLimit) {
      $('#description-char-limit').removeClass('counted-input-error');
    }
  });
}

function projectTitleValidation() {
  const projectTitleCharLimit = $('#project_title').attr('character-limit');
  $('#project_title').on('keyup', (event) => {
    const element = event.currentTarget;
    element.parentNode.querySelector('#project-title-char-limit').innerHTML =
      `${element.value.length}/${projectTitleCharLimit} characters`;
    if (element.value.length > projectTitleCharLimit) {
      $('#project-title-char-limit').addClass('counted-input-error');
    } else if (element.value.length < projectTitleCharLimit) {
      $('#project-title-char-limit').removeClass('counted-input-error');
    }
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
  descriptionValidation();
  projectTitleValidation();
  storageInputs();
  departmentAutocomplete();
  validationClear();
  titleCopySaveExit();
  userRolesAutocomplete();
  copyPastePath();
  wizardNavigation();
}

/* eslint-disable no-console */
/* eslint-disable no-undef */
/* eslint-disable func-names */
window.log_plausible_request_more = function () {
  console.log('log_plausible_request_more event logged');
  plausible('Request More');
};

window.log_plausible_saved_draft_requests = function () {
  console.log('log_plausible_saved_draft_requests event logged');
  plausible('Saved Draft Requests');
};

window.log_plausible_view_submitted_requests = function () {
  console.log(`log_plausible_view_submitted_requests event logged`);
  plausible('View Submitted Requests');
};

window.log_plausible_contact_us_nav = function () {
  console.log('log_plausible_contact_us_from_navigation event logged');
  plausible('Contact Us from Navigation');
};

window.log_plausible_faq = function () {
  console.log('log_plausible_faq event logged');
  plausible('FAQ');
};

window.log_plausible_contact_us_dashboard = function () {
  console.log('log_plausible_contact_us_from_dashboard event logged');
  plausible('Contact Us from Dashboard');
};

window.log_plausible_download = function () {
  console.log(`log_plausible_download event logged`);
  plausible('Download');
};

window.log_plausible_project = function () {
  console.log('log_plausible_project event logged');
  plausible('Project');
};
/* eslint-enable no-console */
/* eslint-enable no-undef */
/* eslint-enable func-names */

window.addEventListener('load', () => initPage());
window.addEventListener('turbo:render', () => initPage());
