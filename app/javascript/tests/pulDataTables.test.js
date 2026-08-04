import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import $ from 'jquery';

// Minimal DOM table matching dashboard listing structure (8 columns)
function mountProjectsTable(rowCount = 20) {
  document.body.innerHTML = `
    <table id="projects-listing" width="100%" role="table">
      <thead>
        <tr class="project heading screenreader-only">
          <th scope="col">display</th>
          <th scope="col">title</th>
          <th scope="col">status</th>
          <th scope="col">type</th>
          <th scope="col">role</th>
          <th scope="col">download</th>
          <th scope="col">activity</th>
          <th scope="col">quota usage</th>
        </tr>
      </thead>
      <tbody>
        ${Array.from(
          { length: rowCount },
          (_, i) => `
          <tr class="project">
            <td>row ${i}</td>
            <td style="display: none">title ${i}</td>
            <td style="display: none">status</td>
            <td style="display: none">type</td>
            <td style="display: none">role</td>
            <td style="display: none">download</td>
            <td style="display: none">activity</td>
            <td style="display: none">quota</td>
          </tr>`,
        ).join('')}
      </tbody>
    </table>
  `;
}

describe('setupTable', () => {
  beforeEach(() => {
    // jsdom needs Option for DataTables length menu
    if (typeof globalThis.Option === 'undefined') {
      globalThis.Option = window.Option;
    }
    mountProjectsTable(20);
  });

  afterEach(() => {
    // Destroy any prior DataTable instance and reset DOM
    if ($.fn.dataTable?.isDataTable?.('#projects-listing')) {
      $('#projects-listing').DataTable().destroy();
    }
    document.body.innerHTML = '';
    vi.resetModules();
  });

  it('registers DataTables and paginates 8 rows per page', async () => {
    const { setupTable } = await import('../entrypoints/pulDataTables.js');

    expect($.fn.dataTable).toBeTypeOf('function');

    setupTable('#projects-listing');

    expect($.fn.dataTable.isDataTable('#projects-listing')).toBe(true);

    const info = document.querySelector('.dataTables_info');
    expect(info).not.toBeNull();
    expect(info.textContent).toMatch(/1\s*-\s*8 out of 20 shown/);

    // DataTables hides non-current page rows
    const visible = [...document.querySelectorAll('#projects-listing tbody tr')].filter(
      (row) => row.style.display !== 'none',
    );
    expect(visible.length).toBe(8);
  });

  it('no-ops when the table is missing', async () => {
    document.body.innerHTML = '';
    const { setupTable } = await import('../entrypoints/pulDataTables.js');
    expect(() => setupTable('#missing-table')).not.toThrow();
  });
});
