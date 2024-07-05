// eslint-disable-next-line import/prefer-default-export
export function displayMediafluxVersion(url, authenticated) {
  const placeholderInPage = $('#mediaflux_version').length === 1;
  if (placeholderInPage === true && authenticated) {
    $.ajax({
      type: 'GET',
      url,
      success(data) {
        $('#mediaflux_version').text(`| Mediaflux: ${data.version}`);
      },
      error(_jqXHR, _textStatus, errorThrown) {
        console.error(errorThrown);
      },
    });
  }
}
