// eslint-disable-next-line import/prefer-default-export
export function displayMediafluxVersion() {
  const placeholderInPage = $('#mediaflux_version').length === 1;
  if (placeholderInPage === true) {
    $.ajax({
      type: 'GET',
      url: '/mediaflux_info.json',
      success(data) {
        $('#mediaflux_version').text(`| Mediaflux: ${data.version}`);
      },
    });
  }
}
