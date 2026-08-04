import $ from 'jquery';
// Legacy package exports a factory under CommonJS/ESM bundlers; it does not
// always auto-register on jQuery when Vite transforms the UMD wrapper.
import dataTablesFactory from 'datatables';

// Attach DataTables to this module's jQuery instance once.
if (typeof dataTablesFactory === 'function' && !$.fn.dataTable) {
  dataTablesFactory(window, $);
}

// Setup DataTables for the index tabs
//   DataTables was included as a yarn package
export function setupTable(tableId) {
  const table = $(tableId);
  // jQuery collections are always truthy — check length so missing tables no-op
  if (!table.length) {
    return;
  }

  if (!$.fn.dataTable) {
    // eslint-disable-next-line no-console
    console.error('DataTables failed to register on jQuery; pagination disabled');
    return;
  }

  // Avoid "Cannot reinitialise DataTable" if setupTable runs more than once
  if ($.fn.dataTable.isDataTable(tableId)) {
    return;
  }

  // Show sorting and pagination at this point
  // Likely will want searching soon
  const datasetOptions = {
    order: [],
    pageLength: 8,
    searching: false,
    // use example spanish translation to know what to change in language https://cdn.datatables.net/plug-ins/2.1.8/i18n/es-ES.json
    language: {
      // Keep "_END_ out of _TOTAL_" so UI/tests still match "8 out of 20 shown"
      // while also showing the range start when on later pages.
      info: '_START_ - _END_ out of _TOTAL_ shown',
      paginate: { next: '>', previous: '<' },
    },
    columnDefs: [
      {
        targets: 0,
        searchable: false,
        orderable: false,
      },
    ],
  };

  table.dataTable(datasetOptions);
}

export default setupTable;
