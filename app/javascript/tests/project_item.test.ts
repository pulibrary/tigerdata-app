// @vitest-environment jsdom

import { mount } from '@vue/test-utils';
import { beforeEach, afterEach, describe, it, expect } from 'vitest';

import ProjectItem from '../vue_components/project_item.vue';
import { MediafluxFile } from '../components/Project.ts';

describe('ProjectItem', () => {
  let wrapper: any;
  let filePath: string = '/princeton/path/to/file.txt';

  beforeEach(() => {
    const currentObject: MediafluxFile = {
      path: filePath,
      name: 'file.txt',
      type: 'file',
      size: '2048',
      created_at: '2024-06-01T12:00:00Z',
      last_modified: '2024-05-01T12:00:00Z',
      collection: false,
    };
    wrapper = mount(ProjectItem, {
      props: {
        currentObject,
      },
    });
  });

  afterEach(() => {
    wrapper.unmount();
  });

  it('mounts to the DOM as a Vue component', () => {
    const sectionElement: any = wrapper.find('section.project-file');
    expect(sectionElement.exists()).toBe(true);
  });

  it('renders the file name', () => {
    const fileNameElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="fileName"]',
    );

    expect(fileNameElement.text()).toBe('file.txt');
  });

  it('updates the file name when the object state is updated', async () => {
    const fileNameElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="fileName"]',
    );

    expect(fileNameElement.text()).toBe('file.txt');

    const newObject: MediafluxFile = {
      path: filePath,
      name: '2.txt',
      type: 'file',
      size: '2048',
      created_at: '2024-06-01T12:00:00Z',
      last_modified: '2024-05-01T12:00:00Z',
      collection: false,
    };
    await wrapper.setProps({ currentObject: newObject });
    expect(fileNameElement.text()).toBe('2.txt');
  });

  it('renders the file size', () => {
    const fileSizeElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="fileSize"]',
    );

    expect(fileSizeElement.text()).toBe('2048');
  });

  it('updates the file size when the object state is updated', async () => {
    const fileSizeElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="fileSize"]',
    );

    expect(fileSizeElement.text()).toBe('2048');

    const newObject: MediafluxFile = {
      path: filePath,
      name: 'file.txt',
      type: 'file',
      size: '4096',
      created_at: '2024-06-01T12:00:00Z',
      last_modified: '2024-05-01T12:00:00Z',
      collection: false,
    };
    await wrapper.setProps({ currentObject: newObject });
    expect(fileSizeElement.text()).toBe('4096');
  });

  it('renders the file type', () => {
    const fileTypeElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="fileType"]',
    );

    expect(fileTypeElement.text()).toBe('file');
  });

  it('updates the file type when the object state is updated', async () => {
    const fileTypeElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="fileType"]',
    );

    expect(fileTypeElement.text()).toBe('file');

    const newObject: MediafluxFile = {
      path: filePath,
      name: 'file.txt',
      type: 'text/plain',
      size: '2048',
      created_at: '2024-06-01T12:00:00Z',
      last_modified: '2024-05-01T12:00:00Z',
      collection: false,
    };
    await wrapper.setProps({ currentObject: newObject });
    expect(fileTypeElement.text()).toBe('text/plain');
  });

  it('renders the last modified date', () => {
    const modifiedDateElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="modifiedDate"]',
    );

    expect(modifiedDateElement.text()).toBe('2024-05-01T12:00:00Z');
  });

  it('updates the last modified date when the object state is updated', async () => {
    const modifiedDateElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="modifiedDate"]',
    );

    expect(modifiedDateElement.text()).toBe('2024-05-01T12:00:00Z');

    const newObject: MediafluxFile = {
      path: filePath,
      name: 'file.txt',
      type: 'file',
      size: '2048',
      created_at: '2024-06-01T12:00:00Z',
      last_modified: '2024-06-15T12:00:00Z',
      collection: false,
    };
    await wrapper.setProps({ currentObject: newObject });
    expect(modifiedDateElement.text()).toBe('2024-06-15T12:00:00Z');
  });

  it('renders the location path', () => {
    const locationElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="location"]',
    );

    expect(locationElement.text()).toBe('/path/to/file.txt');
  });

  it('updates the location path when the object state is updated', async () => {
    const locationElement: any = wrapper.find(
      '.project-file-attribute[data-attribute-name="location"]',
    );

    expect(locationElement.text()).toBe('/path/to/file.txt');

    const newObject: MediafluxFile = {
      path: '/princeton/path/to/newfile.txt',
      name: 'newfile.txt',
      type: 'file',
      size: '2048',
      created_at: '2024-06-01T12:00:00Z',
      last_modified: '2024-05-01T12:00:00Z',
      collection: false,
    };
    await wrapper.setProps({ currentObject: newObject });
    expect(locationElement.text()).toBe('/path/to/newfile.txt');
  });

  describe('when the object is a collection (folder)', () => {
    beforeEach(() => {
      const collectionObject: MediafluxFile = {
        path: '/princeton/path/to/folder',
        name: 'folder',
        type: 'collection',
        size: '0',
        created_at: '2024-06-01T12:00:00Z',
        last_modified: '2024-05-01T12:00:00Z',
        collection: true,
      };
      wrapper = mount(ProjectItem, {
        props: {
          currentObject: collectionObject,
        },
      });
    });

    afterEach(() => {
      wrapper.unmount();
    });

    it('renders "Folder Name" header instead of "File Name"', () => {
      const header: any = wrapper.find('header[data-attribute-name="fileName"]');
      expect(header.text()).toBe('Folder Name');
    });

    it('does not render the file type attribute', () => {
      const fileTypeElement: any = wrapper.find(
        '.project-file-attribute[data-attribute-name="fileType"]',
      );
      expect(fileTypeElement.exists()).toBe(false);
    });

    it('renders folder size instead of file size', () => {
      const folderSizeElement: any = wrapper.find(
        '.project-file-attribute[data-attribute-name="folderSize"]',
      );
      expect(folderSizeElement.exists()).toBe(true);
    });

    it('renders item count', () => {
      const itemCountElement: any = wrapper.find(
        '.project-file-attribute[data-attribute-name="itemCount"]',
      );
      expect(itemCountElement.exists()).toBe(true);
    });
  });
});
