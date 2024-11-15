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

window.bootstrap = bootstrap;
window.displayMediafluxVersion = displayMediafluxVersion;
window.showCreateScript = showCreateScript;

function initDataUsers() {
  function counterIncrement(counterId) {
    let counter = parseInt($(`#${counterId}`).val(), 10);
    counter += 1;
    $(`#${counterId}`).val(counter);
    return counter;
  }

  function addUserHtml(netIdToAdd, elementId, listElementId, textElementId) {
    const html = `<input id="${elementId}" name="${elementId}" value="${netIdToAdd}" readonly class="added_user_textbox" />
      <span id="${elementId}_delete_icon">
        <a class="delete-ro-user" data-el-id="${elementId}" data-uid="${netIdToAdd}" href="#" title="Revoke user ability to read">
            <i class="bi bi-trash delete_icon" data-el-id="${elementId}" data-uid="${netIdToAdd}"></i>
        </a>
        <br/>
      </span>`;
    $(`#${listElementId}`).append(html);
    $(`#${textElementId}`).val('');
    $(`#${textElementId}`).focus();
  }

  // Adds a read-only user
  $('#btn-add-ro-user').on('click', () => {
    const netIdToAdd = $('#ro-user-uid-to-add').val();
    if (netIdToAdd.trim() === '') {
      // nothing to do
      return false;
    }

    const counter = counterIncrement('ro_user_counter');
    const roUserId = `ro_user_${counter}`;
    addUserHtml(netIdToAdd, roUserId, 'ro-users-list', 'ro-user-uid-to-add');
    return false;
  });

  // Adds a read-write user
  $('#btn-add-rw-user').on('click', () => {
    const netIdToAdd = $('#rw-user-uid-to-add').val();
    if (netIdToAdd.trim() === '') {
      // nothing to do
      return false;
    }

    const counter = counterIncrement('rw_user_counter');
    const rwUserId = `rw_user_${counter}`;
    addUserHtml(netIdToAdd, rwUserId, 'rw-users-list', 'rw-user-uid-to-add');
    return false;
  });

  // Wire up the delete button for all read-only users.
  //
  // Notice the use of $(document).on("click", selector, ...) instead of the
  // typical $(selector).on("click", ...). This syntax is required so that
  // we can detect the click even on HTML elements _added on the fly_ which
  // is the case when a user adds a new submitter or admin to the group.
  // Reference: https://stackoverflow.com/a/17086311/446681
  $(document).on('click', '.delete-ro-user', (el) => {
    const uid = $(el.target).data('uid');
    const roUserId = $(el.target).data('el-id');
    const roUserDeleteIcon = `${roUserId}_delete_icon`;
    const message = `Revoke read-only access to user ${uid}`;
    if (window.confirm(message)) {
      $(`#${roUserId}`).remove();
      $(`#${roUserDeleteIcon}`).remove();
    }
    return false;
  });

  // Wire up the delete button for all read-write users.
  $(document).on('click', '.delete-rw-user', (el) => {
    const uid = $(el.target).data('uid');
    const rwUserId = $(el.target).data('el-id');
    const rwUserDeleteIcon = `${rwUserId}_delete_icon`;
    const message = `Revoke read-write access to user ${uid}`;
    if (window.confirm(message)) {
      $(`#${rwUserId}`).remove();
      $(`#${rwUserDeleteIcon}`).remove();
    }
    return false;
  });

  // Render the pre-existing read-only users on the record
  $('.ro-user-item').each((ix, el) => {
    const counter = counterIncrement('ro_user_counter');
    const roUserId = `ro_user_${counter}`;
    const netIdToAdd = $(el).data('uid');
    addUserHtml(netIdToAdd, roUserId, 'ro-users-list', 'ro-user-uid-to-add');
  });

  // Render the pre-existing read-write users on the record
  $('.rw-user-item').each((ix, el) => {
    const counter = counterIncrement('rw_user_counter');
    const rwUserId = `rw_user_${counter}`;
    const netIdToAdd = $(el).data('uid');
    addUserHtml(netIdToAdd, rwUserId, 'rw-users-list', 'rw-user-uid-to-add');
  });
}

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
        success() { // on success..
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

function tabNav() {
  $('#tab-nav').on('mouseenter', (el) => {
    const element = el;
    element.preventDefault();
    const tab = document.getElementById('tab-nav');

    if (!tab.classList.contains('active')) {
      tab.style.borderBottom = 'solid';
      tab.style.borderColor = '#121212';
    }
  });

  $('#tab-nav').on('mouseleave', (el) => {
    const element = el;
    element.preventDefault();
    const tab = document.getElementById('tab-nav');

    if (!tab.classList.contains('active')) {
      tab.style.border = 'none';
    }
  });

  $('#tab-nav').on('click', (el) => {
    const element = el;
    element.preventDefault();
    const tab = document.getElementById('tab-nav');
    // change background color to red
    tab.style.borderBottom = 'solid';
    tab.style.borderColor = '#E77500';
    tab.classList.add('active');
  });
}

function initPage() {
  $('#test-jquery').click((event) => {
    setTargetHtml(event, 'jQuery works!');
  });
  initDataUsers();
  initListContentsModal();
  showMoreLessContent();
  showMoreLessSysAdmin();
  emulate();
  showValidationError();
  tabNav();
}

window.addEventListener('load', () => initPage());
window.addEventListener('turbo:render', () => initPage());
