// Sets up the display of the File Explorer.
// See ./app/views/projects/_file_explorer.html.erb for the HTML.
//
// eslint-disable-next-line import/prefer-default-export
export function setupFileExplorer() {
  $(() => {
    // Keep track of paths the user navigates into
    const pathBreadcrumbs = [];

    // Update the file details on the right panel
    function fileDetails(fileName, fileSize, lastUpdated, fullName) {
      $('#right-panel-filename').text(fileName);
      $('#right-panel-size').text(fileSize);
      $('#right-panel-last-updated').text(lastUpdated);
      $('#right-panel-fullname').text(fullName);
    }

    // Shows the what we are fetching new data
    function showSpinner() {
      $('#load-more-spinner').removeClass('hidden-element');
      $('#load-more-loading').removeClass('hidden-element');
      $('#load-more').addClass('hidden-element');
    }

    // Hides the spinner
    function hideSpinner() {
      $('#load-more-spinner').addClass('hidden-element');
      $('#load-more-loading').addClass('hidden-element');
    }

    function showError(status, message) {
      $('#error-message').text(`${message} (${status})`);
      $('#error-panel').removeClass('hidden-element');
    }

    function hideError() {
      $('#error-message').text('');
      $('#error-panel').addClass('hidden-element');
    }

    // Reset the state values of the file explorer
    function resetFileExplorerState() {
      $('#current-path-text').val('');
      $('#current-path-id').val('');
      $('#iterator-id').val('0');
      $('#complete').val('false');
      hideSpinner();
    }

    // Adds a path to the breadcrumbs
    function addPathToBreadcrumbs(path, pathId) {
      let i;
      let alreadyAdded = false;

      if (pathId === 0) {
        return;
      }

      for (i = 0; i < pathBreadcrumbs.length; i += 1) {
        if (pathBreadcrumbs[i].pathId === pathId) {
          alreadyAdded = true;
          break;
        }
      }

      if (alreadyAdded === false) {
        // Add the path and keep the array sorted by path
        pathBreadcrumbs.push({ path, pathId });
        pathBreadcrumbs.sort((a, b) => a.path.localeCompare(b.path));
      }
    }

    // Render the path breadcrumbs
    function renderPathBreadcrums(fileListUrl, currentPath) {
      // Delete any path from the breadcrumbs that is deeper than the current path
      for (let i = 0; i < pathBreadcrumbs.length; i += 1) {
        if (pathBreadcrumbs[i].path > currentPath) {
          // the paths are sorted, so once we find one we delete
          // from that path forward with splice
          pathBreadcrumbs.splice(i);
          break;
        }
      }

      // Clear the display entirely
      $('#pathBreadcrumbs').empty();

      // Re-display the breadcrumbs with the current data
      for (let i = 0; i < pathBreadcrumbs.length; i += 1) {
        const { path } = pathBreadcrumbs[i];
        const { pathId } = pathBreadcrumbs[i];
        const tokens = path.split('/');
        const lastPath = i === pathBreadcrumbs.length - 1;
        let pathDisplay;
        let pathElement;

        if (i === 0) {
          // use the entire path (e.g. /tigerdata/my-project)
          pathDisplay = path;
        } else {
          // use only the last portion of the path (e.g. lab-123)
          pathDisplay = tokens[tokens.length - 1];
        }

        if (lastPath) {
          // render as a text element
          pathElement = $('<span>').text(pathDisplay);
        } else {
          // render as a hyperlink
          pathElement = $('<a>')
            .attr('href', `${fileListUrl}?path=${path}&pathId=${pathId}`)
            .addClass('path-breadcrumb-link')
            .text(pathDisplay);
        }

        $('#pathBreadcrumbs').append(pathElement);
        if (lastPath === false) {
          $('#pathBreadcrumbs').append($('<span>').text(' > '));
        }
      }
    }

    // Uploads the file list for the current path
    function loadFileList() {
      const path = $('#current-path-text').val();
      const pathId = parseInt($('#current-path-id').val(), 10);
      const iteratorId = parseInt($('#iterator-id').val(), 10);
      const fileExplorerUrl = $('#file-explorer-url').val();
      const table = $('#file_explorer_body');

      // Clear the current file details
      fileDetails('', '', '', '');
      hideError();

      showSpinner();

      $.ajax({
        url: `${fileExplorerUrl}?path=${path}&pathId=${pathId}&iteratorId=${iteratorId}`,
      })
        .done((data) => {
          let firstFile = null;

          $('#current-path').text(data.currentPath);
          $('#current-path-text').val(data.currentPath);
          $('#current-path-id').val(data.currentPathId);
          $('#iterator-id').val(data.iteratorId);
          $('#complete').val(data.complete);

          // Update the path breadcrumbs
          addPathToBreadcrumbs(data.currentPath, data.currentPathId);
          renderPathBreadcrums(data.fileListUrl, data.currentPath);

          hideSpinner();
          if (data.complete === true) {
            $('#load-more').addClass('hidden-element');
          } else {
            $('#load-more').removeClass('hidden-element');
          }

          // Clear the file list if we are showing a new folder
          // (i.e. we are not re-using an iterator)
          if (iteratorId === 0) {
            table.empty();
          }

          // Render the files and folders
          for (let i = 0; i < data.files.length; i += 1) {
            const file = data.files[i];
            let iconColumn;
            let nameColumn;
            let sizeColumn;
            let dateColumn;
            let rowClass;

            if (file.collection === true) {
              // It's a folder
              rowClass = 'file-explorer-folder';
              iconColumn = $('<i>').addClass('bi bi-folder-fill');
              nameColumn = $('<a>')
                .attr('href', `${data.fileListUrl}?path=${file.path}&pathId=${file.id}`)
                .addClass('file-explorer-folder')
                .text(file.name);
              sizeColumn = $('<span>').text('');
              dateColumn = $('<span>').text('');
            } else {
              // It's a file
              rowClass = 'file-explorer-file';
              iconColumn = $('<i>').addClass('bi bi-file-earmark-text');
              nameColumn = $('<span>').text(file.name);
              sizeColumn = $('<span>').text(file.size);
              dateColumn = $('<span>').text(file.last_modified_mf);

              // Save the id of the very first file in the list (if any)
              if (firstFile === null) {
                firstFile = `#row-${file.id}`;
              }
            }

            // Append the folder/file row to the table
            table.append(
              $('<tr>')
                .attr('id', `row-${file.id}`)
                .addClass(rowClass)
                .append($('<td>').append(iconColumn))
                .append($('<td>').addClass('name-column').append(nameColumn))
                .append($('<td>').addClass('size-column').append(sizeColumn))
                .append($('<td>').addClass('date-column').append(dateColumn)),
            );
          }

          // Display the file information for the first file in the current folder
          if (firstFile !== null) {
            $(firstFile).click();
          }
        })
        .fail((_jqXHR, status, message) => {
          showError(status, message);
          resetFileExplorerState();
        });
    }

    // When clicking on a folder load the data for that folder.
    //
    // Notice that we set the on-click on the $(document) so that it applies
    // to rows added on the fly.
    $(document).on('click', '.file-explorer-folder', (element) => {
      const targetUrl = new URL(element.target.href);
      const path = targetUrl.searchParams.get('path');
      const pathId = targetUrl.searchParams.get('pathId');
      $('#current-path-text').val(path);
      $('#current-path-id').val(pathId);
      $('#iterator-id').val('0');
      $('#complete').val('false');
      loadFileList();
      return false;
    });

    // When clicking a file mark the current file as selected.
    $(document).on('click', '.file-explorer-file', (element) => {
      // Mark the current row as selected...
      $('#file_explorer>tbody>tr').removeClass('active-row');
      const rowId = element.currentTarget.id;
      $(`#${rowId}`).addClass('active-row');

      // ...and display the file details
      const fileName = $(`#${rowId}>td.name-column>span`).text();
      const fileSize = $(`#${rowId}>td.size-column>span`).text();
      const lastUpdated = $(`#${rowId}>td.date-column>span`).text();
      const currentPathText = $('#current-path-text').val();
      const fullName = `${currentPathText}/${fileName}`;
      fileDetails(fileName, fileSize, lastUpdated, fullName);
      return false;
    });

    // When clicking a breadcrumb link load the file list for the selected path
    $(document).on('click', '.path-breadcrumb-link', (element) => {
      const targetUrl = new URL(element.target.href);
      const path = targetUrl.searchParams.get('path');
      const pathId = targetUrl.searchParams.get('pathId');
      $('#current-path-text').val(path);
      $('#current-path-id').val(pathId);
      $('#iterator-id').val('0');
      $('#complete').val('false');
      loadFileList();
      return false;
    });

    // Reload from the root folder for the project
    $('#back-home').on('click', () => {
      resetFileExplorerState();
      loadFileList();
      return false;
    });

    // Load more items for the current folder
    $('#load-more').on('click', () => {
      loadFileList();
      return false;
    });

    // Perform the inital load of files
    resetFileExplorerState();
    loadFileList();
  });
}
