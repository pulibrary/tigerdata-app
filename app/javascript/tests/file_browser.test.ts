// @vitest-environment jsdom

import { mount } from '@vue/test-utils';
import { beforeEach, afterEach, describe, it, expect, vi } from 'vitest';

import FileBrowser from '../vue_components/file_browser.vue';
import { MediafluxFile } from '../components/Project.ts';

describe('FileBrowser', () => {
  let wrapper: any;
  const currentPath: string = '/princeton/path/';
  const collectionPath: string = '/princeton/path/to/collection';
  const currentCollection: MediafluxFile = {
    path: collectionPath,
    name: 'collection1',
    type: 'collection',
    size: '0',
    created_at: '2024-06-01T12:00:00Z',
    last_modified: '2024-05-01T12:00:00Z',
    collection: true,
    id: 'collection-123',
  };
  const currentCollectionJSON: string = JSON.stringify(currentCollection);

  const filePath: string = '/princeton/path/to/file.txt';
  const currentObject: MediafluxFile = {
    path: filePath,
    name: 'file.txt',
    type: 'file',
    size: '2048',
    created_at: '2024-06-01T12:00:00Z',
    last_modified: '2024-05-01T12:00:00Z',
    collection: false,
  };

  const anotherFile: MediafluxFile = {
    path: '/princeton/path/to/another.txt',
    name: 'another.txt',
    type: 'file',
    size: '4096',
    created_at: '2024-06-02T12:00:00Z',
    last_modified: '2024-05-02T12:00:00Z',
    collection: false,
  };

  const subCollection: MediafluxFile = {
    path: '/princeton/path/to/subcollection',
    name: 'subcollection',
    type: 'collection',
    size: '0',
    created_at: '2024-06-03T12:00:00Z',
    last_modified: '2024-05-03T12:00:00Z',
    collection: true,
    id: 'subcollection-456',
  };

  let files: MediafluxFile[] = [currentObject];

  const directoryListUrl: string = 'http://localhost:3000/api/directory_list';
  const fileDisplayLimit: number = 100;

  beforeEach(() => {
    wrapper = mount(FileBrowser, {
      props: {
        files,
        directoryListUrl,
        fileDisplayLimit,
        currentPath,
        currentCollection: currentCollectionJSON,
      },
    });
  });

  afterEach(() => {
    wrapper.unmount();
  });

  it('mounts to the DOM as a Vue component', () => {
    const sectionElement: any = wrapper.find('.file-browser-container');
    expect(sectionElement.exists()).toBe(true);
  });

  it('renders rows for each child collection or file asset', async () => {
    const fileNameElement: any = wrapper.find('.file-data');

    expect(fileNameElement.exists()).toBe(true);
  });

  describe('when the collection has no files', async () => {
    beforeEach(() => {
      files = [];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });
    });

    it('displays a message indicating the collection is empty', () => {
      const emptyMessageElement: any = wrapper.find('.empty-dir-text');
      expect(emptyMessageElement.exists()).toBe(true);
    });
  });

  describe('file selection', () => {
    beforeEach(() => {
      files = [currentObject, anotherFile];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });
    });

    it('selects a file when clicking on a row', async () => {
      const rows = wrapper.findAll('.file-browser-row');
      expect(rows).toHaveLength(2);

      // Click the second file
      await rows[1].trigger('mousedown');

      // Wait for the next tick to ensure reactivity updates
      await wrapper.vm.$nextTick();

      // Check that the second row is selected
      expect(rows[1].classes()).toContain('selected-object');
    });

    it('clears previous selection when clicking on a new file', async () => {
      const rows = wrapper.findAll('.file-browser-row');

      // Click the first file
      await rows[0].trigger('mousedown');
      await wrapper.vm.$nextTick();

      // Click the second file
      await rows[1].trigger('mousedown');
      await wrapper.vm.$nextTick();

      // First row should not be selected anymore
      expect(rows[0].classes()).not.toContain('selected-object');
      // Second row should be selected
      expect(rows[1].classes()).toContain('selected-object');
    });

    it('updates currentObject when a file is selected', async () => {
      const rows = wrapper.findAll('.file-browser-row');

      // Click the second file
      await rows[1].trigger('mousedown');
      await wrapper.vm.$nextTick();

      // Check that currentObject was updated
      expect(wrapper.vm.currentObject.name).toBe('another.txt');
    });
  });

  describe('collection navigation', () => {
    beforeEach(() => {
      // Mock fetch globally
      globalThis.fetch = vi.fn() as any;
    });

    afterEach(() => {
      vi.restoreAllMocks();
    });

    it('navigates into a collection when clicking on it', async () => {
      files = [currentObject, subCollection];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });

      // Mock the fetch response
      const mockFiles: MediafluxFile[] = [
        {
          path: '/princeton/path/to/subcollection/nested.txt',
          name: 'nested.txt',
          type: 'file',
          size: '1024',
          created_at: '2024-06-04T12:00:00Z',
          last_modified: '2024-05-04T12:00:00Z',
          collection: false,
        },
      ];

      (globalThis.fetch as any).mockResolvedValueOnce({
        json: async () => ({ files: mockFiles, complete: true }),
      });

      // Find the collection cell and click it
      const collectionCell = wrapper.find('.browser-collection');
      expect(collectionCell.exists()).toBe(true);

      await collectionCell.trigger('mousedown');
      await wrapper.vm.$nextTick();

      // Wait for async operations
      await new Promise((resolve) => setTimeout(resolve, 0));
      await wrapper.vm.$nextTick();

      // Verify fetch was called with correct URL
      expect(globalThis.fetch).toHaveBeenCalledWith(
        `${directoryListUrl}?pathid=${subCollection.id}`
      );

      // Verify the displayed files were updated
      expect(wrapper.vm.displayedFiles).toHaveLength(1);
      expect(wrapper.vm.displayedFiles[0].name).toBe('nested.txt');

      // Verify the path was updated (without hidden root)
      expect(wrapper.vm.displayedPath).toBe('/path/to/subcollection');

      // Verify breadcrumb folders were updated
      expect(wrapper.vm.displayedFolders).toHaveLength(2);
      expect(wrapper.vm.displayedFolders[1].name).toBe('subcollection');
    });

    it('shows loading state while fetching collection contents', async () => {
      files = [subCollection];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });

      // Create a promise we can control
      let resolvePromise: any;
      const fetchPromise = new Promise((resolve) => {
        resolvePromise = resolve;
      });

      (globalThis.fetch as any).mockReturnValueOnce(fetchPromise);

      const collectionCell = wrapper.find('.browser-collection');
      await collectionCell.trigger('mousedown');
      await wrapper.vm.$nextTick();

      // Check loading state is active
      expect(wrapper.vm.isLoadingFiles).toBe(true);

      // Resolve the fetch
      resolvePromise({
        json: async () => ({ files: [], complete: true }),
      });

      await wrapper.vm.$nextTick();
      await new Promise((resolve) => setTimeout(resolve, 0));
      await wrapper.vm.$nextTick();

      // Check loading state is cleared
      expect(wrapper.vm.isLoadingFiles).toBe(false);
    });
  });

  describe('breadcrumb navigation', () => {
    beforeEach(() => {
      globalThis.fetch = vi.fn() as any;
    });

    afterEach(() => {
      vi.restoreAllMocks();
    });

    it('navigates back to a parent folder when clicking a breadcrumb', async () => {
      // Setup: simulate being in a nested folder
      files = [currentObject];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });

      // Add a nested folder to the breadcrumb
      const parentFolder = {
        id: 'collection-123',
        path: '/princeton/path/to/collection',
        name: 'collection1',
      };
      const nestedFolder = {
        id: 'subcollection-456',
        path: '/princeton/path/to/collection/nested',
        name: 'nested',
      };
      wrapper.vm.displayedFolders = [parentFolder, nestedFolder];
      await wrapper.vm.$nextTick();

      // Mock the fetch response for going back to parent
      const mockFiles: MediafluxFile[] = [subCollection];
      (globalThis.fetch as any).mockResolvedValueOnce({
        json: async () => ({ files: mockFiles, complete: true }),
      });

      // Find and click the first breadcrumb
      const breadcrumbs = wrapper.findAll('.breadcrumb-list li');
      await breadcrumbs[0].trigger('mousedown');
      await wrapper.vm.$nextTick();

      // Wait for async operations
      await new Promise((resolve) => setTimeout(resolve, 0));
      await wrapper.vm.$nextTick();

      // Verify fetch was called
      expect(globalThis.fetch).toHaveBeenCalledWith(`${directoryListUrl}?pathid=collection-123`);

      // Verify files were updated
      expect(wrapper.vm.displayedFiles).toHaveLength(1);
      expect(wrapper.vm.displayedFiles[0].name).toBe('subcollection');

      // Verify breadcrumb trail was truncated (should now only have parentFolder)
      expect(wrapper.vm.displayedFolders.length).toBeGreaterThanOrEqual(1);
      expect(wrapper.vm.displayedFolders[0].name).toBe('collection1');
    });
  });

  describe('preview limit warning', () => {
    it('displays warning when file count exceeds limit', () => {
      const manyFiles: MediafluxFile[] = Array.from({ length: 150 }, (_, i) => ({
        path: `/princeton/path/to/file${i}.txt`,
        name: `file${i}.txt`,
        type: 'file',
        size: '1024',
        created_at: '2024-06-01T12:00:00Z',
        last_modified: '2024-05-01T12:00:00Z',
        collection: false,
      }));

      wrapper = mount(FileBrowser, {
        props: {
          files: manyFiles,
          directoryListUrl,
          fileDisplayLimit: 100,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });

      const warningElement = wrapper.find('.preview-limit-warning');
      expect(warningElement.exists()).toBe(true);

      const warningMessage = warningElement.find('.warning-message');
      expect(warningMessage.text()).toContain('Preview Limit Reached');
      expect(warningMessage.text()).toContain('100 items');
    });

    it('hides warning when file count is within limit', () => {
      files = [currentObject, anotherFile];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit: 100,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });

      const warningElement = wrapper.find('.preview-limit-warning');
      expect(warningElement.exists()).toBe(false);
    });

    it('updates warning based on fetch response completeness', async () => {
      globalThis.fetch = vi.fn() as any;

      files = [subCollection];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit: 100,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });

      // Mock fetch returning incomplete result
      (globalThis.fetch as any).mockResolvedValueOnce({
        json: async () => ({
          files: [currentObject],
          complete: false, // This should trigger the warning
        }),
      });

      const collectionCell = wrapper.find('.browser-collection');
      await collectionCell.trigger('mousedown');
      await wrapper.vm.$nextTick();
      await new Promise((resolve) => setTimeout(resolve, 0));
      await wrapper.vm.$nextTick();

      // Warning should now be displayed
      expect(wrapper.vm.displayWarning).toBe(true);

      vi.restoreAllMocks();
    });
  });

  describe('file vs collection rendering', () => {
    beforeEach(() => {
      files = [currentObject, subCollection];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });
    });

    it('renders collections with underline style', () => {
      const collectionCell = wrapper.find('.browser-collection');
      expect(collectionCell.exists()).toBe(true);
      expect(collectionCell.text()).toBe('subcollection');
    });

    it('renders files without underline style', () => {
      const fileCell = wrapper.find('.browser-file');
      expect(fileCell.exists()).toBe(true);
      expect(fileCell.text()).toBe('file.txt');
    });

    it('displays "--" for collection size', () => {
      const rows = wrapper.findAll('.file-browser-row');
      const collectionRow = rows.find((row: any) =>
        row.text().includes('subcollection')
      );

      const cells = collectionRow.findAll('.file-data');
      // Size should be the 4th cell (index 3)
      expect(cells[3].text()).toBe('--');
    });

    it('displays actual size for files', () => {
      const rows = wrapper.findAll('.file-browser-row');
      const fileRow = rows.find((row: any) => row.text().includes('file.txt'));

      const cells = fileRow.findAll('.file-data');
      // Size should be the 4th cell (index 3)
      expect(cells[3].text()).toBe('2048');
    });
  });

  describe('breadcrumb display', () => {
    it('renders breadcrumb with home icon', () => {
      const homeIcon = wrapper.findComponent({ name: 'HomeIcon' });
      expect(homeIcon.exists()).toBe(true);
    });

    it('renders breadcrumb list with current collection', () => {
      const breadcrumbList = wrapper.find('.breadcrumb-list');
      expect(breadcrumbList.exists()).toBe(true);

      const breadcrumbs = breadcrumbList.findAll('li');
      expect(breadcrumbs).toHaveLength(1);
      expect(breadcrumbs[0].text()).toBe('collection1');
    });

    it('renders copy path component with current path', () => {
      const copyPath = wrapper.findComponent({ name: 'CopyPath' });
      expect(copyPath.exists()).toBe(true);
      expect(copyPath.props('path')).toBe(currentPath);
    });
  });

  describe('initial current object', () => {
    it('sets current object to first file when files are present', () => {
      files = [currentObject, anotherFile];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });

      expect(wrapper.vm.currentObject.name).toBe('file.txt');
    });

    it('sets current object to collection when no files are present', () => {
      files = [];
      wrapper = mount(FileBrowser, {
        props: {
          files,
          directoryListUrl,
          fileDisplayLimit,
          currentPath,
          currentCollection: currentCollectionJSON,
        },
      });

      expect(wrapper.vm.currentObject.name).toBe('collection1');
    });
  });
});
