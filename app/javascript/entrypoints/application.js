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

import { setTargetHtml } from './helper';

window.bootstrap = bootstrap;

function initPage() {
  $('#test-jquery').click((event) => {
    setTargetHtml(event, 'jQuery works!');
  });

  initDataUsers();
}

function initDataUsers() {
  var counterIncrement = function(counterId) {
    var counter = parseInt($(`#${counterId}`).val(), 10);
    counter += 1;
    $(`#${counterId}`).val(counter);
    return counter;
  }

  var addUserHtml = function(netIdToAdd, elementId, listElementId, textElementId) {
    var html = `<input id="${elementId}" name="${elementId}" value="${netIdToAdd}" readonly class="added_user_textbox" />
      <span id="${elementId}_delete_icon">
        <a class="delete-ro-user" data-el-id="${elementId}" data-uid="${netIdToAdd}" href="#" title="Revoke user ability to read">
            <i class="bi bi-trash delete_icon" data-el-id="${elementId}" data-uid="${netIdToAdd}"></i>
        </a>
        <br/>
      </span>`;
    $(`#${listElementId}`).append(html);
    $(`#${textElementId}`).val("");
    $(`#${textElementId}`).focus();
  }

  // Adds a read-only user
  $('#btn-add-ro-user').on('click', () => {
    var netIdToAdd = $('#ro-user-uid-to-add').val();
    if (netIdToAdd.trim() === "") {
      // nothing to do
      return false;
    }

    var counter = counterIncrement('ro_user_counter');
    var roUserId = `ro_user_${counter}`;
    addUserHtml(netIdToAdd, roUserId, 'ro-users-list', 'ro-user-uid-to-add');
    return false;
  });

  // Adds a read-write user
  $('#btn-add-rw-user').on('click', () => {
    var netIdToAdd = $('#rw-user-uid-to-add').val();
    if (netIdToAdd.trim() === "") {
      // nothing to do
      return false;
    }

    var counter = counterIncrement('rw_user_counter');
    var rwUserId = `rw_user_${counter}`;
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
    var uid = $(el.target).data('uid');
    var ro_user_id = $(el.target).data('el-id');
    var ro_user_delete_icon = ro_user_id + "_delete_icon";
    const message = `Revoke read-only access to user ${uid}`;
    if (window.confirm(message)) {
      $("#" + ro_user_id).remove();
      $("#" + ro_user_delete_icon).remove();
    }
    return false;
  });

  // Wire up the delete button for all read-write users.
  $(document).on('click', '.delete-rw-user', (el) => {
    var uid = $(el.target).data('uid');
    var rw_user_id = $(el.target).data('el-id');
    var rw_user_delete_icon = rw_user_id + "_delete_icon";
    const message = `Revoke read-write access to user ${uid}`;
    if (window.confirm(message)) {
      $("#" + rw_user_id).remove();
      $("#" + rw_user_delete_icon).remove();
    }
    return false;
  });

  // Render the pre-existing read-only users on the record
  $('.ro-user-item').each((ix, el) => {
    var counter = counterIncrement('ro_user_counter');
    var roUserId = `ro_user_${counter}`;
    var netIdToAdd = $(el).data("uid");
    addUserHtml(netIdToAdd, roUserId, 'ro-users-list', 'ro-user-uid-to-add');
  });

  // Render the pre-existing read-write users on the record
  $('.rw-user-item').each((ix, el) => {
    var counter = counterIncrement('rw_user_counter');
    var rwUserId = `rw_user_${counter}`;
    var netIdToAdd = $(el).data("uid");
    addUserHtml(netIdToAdd, rwUserId, 'rw-users-list', 'rw-user-uid-to-add');
  });

}

window.addEventListener('load', () => initPage());
window.addEventListener('turbo:render', () => initPage());
