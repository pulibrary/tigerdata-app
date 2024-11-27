export function displayProjectQuota(project, url, authenticated) {
  const placeholderInPage = $('#project_quota').length === 1;
  if (placeholderInPage === true && authenticated) {
    $.ajax({
      type: 'GET',
      url,
      success(data) {
        $('#project_quota').text(`| Project Quota: ${data.quota}`);
      },
      error(_jqXHR, _textStatus, errorThrown) {
        console.error(errorThrown);
      },
    });
  }
}