// @vitest-environment jsdom

import { describe, it, expect } from 'vitest';

import { JSDOM } from 'jsdom';
import {
  MediafluxFile,
  ProjectComponent,
  ProjectFileComponent,
  ProjectFileAttribute,
} from '../components/Project.ts';

describe('ProjectComponent', () => {
  const documentFixture: string = `
<!DOCTYPE html>
  <table id="project-contents">
    <tr>
      <td data-attribute-name="fileName">test.txt</td>
      <td data-attribute-name="fileSize">1024</td>
      <td data-attribute-name="fileType">file</td>
      <td data-attribute-name="modifiedDate">2024-06-01T12:00:00Z</td>
      <td data-attribute-name="location">/path/to/test.txt'</td>
    </tr>
  </table>
  <div class="project-file">
    <div class="project-file-attribute" data-attribute-name="fileName"></div>
    <div class="project-file-attribute" data-attribute-name="fileSize"></div>
    <div class="project-file-attribute" data-attribute-name="fileType"></div>
    <div class="project-file-attribute" data-attribute-name="modifiedDate"></div>
    <div class="project-file-attribute" data-attribute-name="location"></div>
  </div>
</html>
  `;
  const dom = new JSDOM(documentFixture, { url: 'http://localhost/' });
  const { window } = dom;
  const { document } = window;

  it('binds to the DOM and builds a ProjectFileTable instance', () => {
    const project = new ProjectComponent(document);
    expect(project).toBeInstanceOf(ProjectComponent);
    expect(project.file).toBeInstanceOf(ProjectFileComponent);
  });

  it('binds the ProjectFileComponent instance to the DOM', () => {
    const project = new ProjectComponent(document);
    const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;
    expect(projectFileComponent.element).toBe(document.querySelector('.project-file'));
  });

  it('binds the ProjectFileAttribute instance to the DOM', () => {
    const project = new ProjectComponent(document);

    const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;
    expect(projectFileComponent.attributes.size).toBe(5);
  });

  it('listens to state update events for file name', () => {
    const project = new ProjectComponent(document);
    const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;

    const projectFileAttribute: ProjectFileAttribute = projectFileComponent.attributes.get(
      'fileName',
    ) as ProjectFileAttribute;

    const file: MediafluxFile = {
      name: 'test.txt',
      size: '1024',
      path: '/path/to/test.txt',
      last_modified: '2024-06-01T12:00:00Z',
      collection: false,
    };
    ProjectComponent.dispatchProjectStateChange(file, document);

    expect(projectFileAttribute.name).toBe('fileName');
    expect(projectFileAttribute.element.textContent).toBe('test.txt');
  });

  it('listens to state update events for file size', () => {
    const project = new ProjectComponent(document);
    const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;

    const projectFileAttribute: ProjectFileAttribute = projectFileComponent.attributes.get(
      'fileSize',
    ) as ProjectFileAttribute;

    const file: MediafluxFile = {
      name: 'test.txt',
      size: 1024,
      path: '/path/to/test.txt',
      last_modified: '2024-06-01T12:00:00Z',
      collection: false,
    };
    ProjectComponent.dispatchProjectStateChange(file, document);

    expect(projectFileAttribute.name).toBe('fileSize');
    expect(projectFileAttribute.element.textContent).toBe('1024');
  });
  it('listens to state update events for file modification date', () => {
    const project = new ProjectComponent(document);
    const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;

    const projectFileAttribute: ProjectFileAttribute = projectFileComponent.attributes.get(
      'modifiedDate',
    ) as ProjectFileAttribute;

    const file: MediafluxFile = {
      name: 'test.txt',
      size: 1024,
      path: '/path/to/test.txt',
      last_modified: '2024-06-01T12:00:00Z',
      collection: false,
    };
    ProjectComponent.dispatchProjectStateChange(file, document);

    expect(projectFileAttribute.name).toBe('modifiedDate');
    expect(projectFileAttribute.element.textContent).toBe('2024-06-01T12:00:00Z');
  });
  it('listens to state update events for file location', () => {
    const project = new ProjectComponent(document);
    const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;

    const projectFileAttribute: ProjectFileAttribute = projectFileComponent.attributes.get(
      'location',
    ) as ProjectFileAttribute;

    const file: MediafluxFile = {
      name: 'test.txt',
      size: 1024,
      path: '/path/to/test.txt',
      last_modified: '2024-06-01T12:00:00Z',
      collection: false,
    };
    ProjectComponent.dispatchProjectStateChange(file, document);

    expect(projectFileAttribute.name).toBe('location');
    expect(projectFileAttribute.element.textContent).toBe('/path/to/test.txt');
  });
  it('listens to state update events for file type', () => {
    const project = new ProjectComponent(document);
    const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;

    const projectFileAttribute: ProjectFileAttribute = projectFileComponent.attributes.get(
      'fileType',
    ) as ProjectFileAttribute;

    const file: MediafluxFile = {
      name: 'test.txt',
      size: '1024',
      path: '/path/to/test.txt',
      last_modified: '2024-06-01T12:00:00Z',
      collection: false,
    };
    ProjectComponent.dispatchProjectStateChange(file, document);

    expect(projectFileAttribute.name).toBe('fileType');
    expect(projectFileAttribute.element.textContent).toBe('file');
  });
  describe('when a MediafluxFile is a collection', () => {
    it('displays "collection" as the file type', () => {
      const project = new ProjectComponent(document);
      const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;

      const projectFileAttribute: ProjectFileAttribute = projectFileComponent.attributes.get(
        'fileType',
      ) as ProjectFileAttribute;

      const file: MediafluxFile = {
        name: 'test.txt',
        size: '1024',
        path: '/path/to/test.txt',
        last_modified: '2024-06-01T12:00:00Z',
        collection: true,
      };
      ProjectComponent.dispatchProjectStateChange(file, document);

      expect(projectFileAttribute.name).toBe('fileType');
      expect(projectFileAttribute.element.textContent).toBe('collection');
    });
    it('displays the value of "last_modified_mf" for the modification date', () => {
      const project = new ProjectComponent(document);
      const projectFileComponent: ProjectFileComponent = project.file as ProjectFileComponent;

      const projectFileAttribute: ProjectFileAttribute = projectFileComponent.attributes.get(
        'modifiedDate',
      ) as ProjectFileAttribute;

      const file: MediafluxFile = {
        name: 'test.txt',
        size: '1024',
        path: '/path/to/test.txt',
        last_modified_mf: '2024-06-01T12:00:00Z',
        collection: true,
      };
      ProjectComponent.dispatchProjectStateChange(file, document);

      expect(projectFileAttribute.name).toBe('modifiedDate');
      expect(projectFileAttribute.element.textContent).toBe('2024-06-01T12:00:00Z');
    });
  });
});
