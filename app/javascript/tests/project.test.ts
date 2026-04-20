// @vitest-environment jsdom

import { describe, it, expect } from 'vitest';

import { JSDOM } from 'jsdom';
import {
  ProjectComponent,
  ProjectFileTable,
  ProjectFileComponent,
  ProjectFileTableRow,
  ProjectFileAttribute,
} from '../components/Project.ts';

describe('ProjectComponent', () => {
  const documentFixture: string = `
<!DOCTYPE html>
  <table id="project-contents">
    <tr>
      <td data-attribute-name="fileName">test.txt</td>
    </tr>
  </table>
  <div class="project-file">
    <div class="project-file-attribute" data-attribute-name="fileName"></div>
  </div>
</html>
  `;
  const dom = new JSDOM(documentFixture);
  const { window } = dom;
  const { document } = window;

  it('binds to the DOM and builds a ProjectFileTable instance', () => {
    const project = new ProjectComponent(document);
    expect(project).toBeInstanceOf(ProjectComponent);
    expect(project.tables.length).toBe(1);
    expect(project.tables[0]).toBeInstanceOf(ProjectFileTable);
  });

  it('binds the ProjectFileTable instance to the DOM', () => {
    const project = new ProjectComponent(document);
    expect(project.tables.length).toBe(1);
    const projectFileTable: ProjectFileTable = project.tables[0];
    expect(projectFileTable.element).toBe(document.querySelector('table#project-contents'));
  });

  it('binds the ProjectFileComponent instance to the DOM', () => {
    const project = new ProjectComponent(document);
    const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;
    expect(projectFileComponent.element).toBe(document.querySelector('.project-file'));
  });

  it('binds the ProjectFileTableRow instance to the DOM', () => {
    const project = new ProjectComponent(document);
    expect(project.tables.length).toBe(1);
    const projectFileTable: ProjectFileTable = project.tables[0];
    expect(projectFileTable.rows.length).toBe(1);
    const projectFileTableRow: ProjectFileTableRow = projectFileTable.rows[0];
    expect(projectFileTableRow.element).toBe(
      document.querySelector('table#project-contents tr'),
    );
  });

  it('binds the ProjectFileAttribute instance to the DOM', () => {
    const project = new ProjectComponent(document);
    const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;
    expect(projectFileComponent.attributes.size).toBe(1);
    const projectFileAttribute: ProjectFileAttribute = projectFileComponent.attributes.get(
      'fileName',
    ) as ProjectFileAttribute;
    expect(projectFileAttribute.element).toBe(
      document.querySelector('.project-file-attribute'),
    );
    expect(projectFileAttribute.name).toBe('fileName');
    expect(projectFileAttribute.value).toBe('test.txt');
  });
});
