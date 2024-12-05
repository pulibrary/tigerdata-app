import 'datatables';

// Setup DataTables for the index tabs
//   DataTables was included as a yarn package
export function setupTable(tableId) {
  const table = $(tableId);
  // Show sorting and pagination at this point
  // Likely will want searching soon
  const datasetOptions = {
    order: [],
    pageLength: 8,
    searching: false,
    // use example spanish translation to know what to change in language https://cdn.datatables.net/plug-ins/2.1.8/i18n/es-ES.json
    language: {
      info: '_START_ - _END_ out of _TOTAL_ shown',
      paginate: { next: '>', previous: '<' },
    },
  };

  // If we have a table initialize it with DataTables
  if (table) {
    table.dataTable(datasetOptions);
  }
}

export default setupTable;
