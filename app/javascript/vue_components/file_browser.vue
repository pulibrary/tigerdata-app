<template>
  <div class="file-browser-container">
    <div class="breadcrumb-container">
      <home-icon class="home-icon"></home-icon>
      <ol class="breadcrumb-list col-auto">
        <li v-for="(path, i) in displayedFolders" @mousedown="onClickBreadcrumb(path)">
          {{ path.name }}
        </li>
      </ol>
      <copy-path class="col" :path="displayedPath"> </copy-path>
    </div>

    <div v-if="displayWarning" class="preview-limit-frame">
      <div class="preview-limit-warning">
        <exclamation-triangle color="#FBC129"></exclamation-triangle>
        <div class="warning-message">
          <header>Preview Limit Reached</header>
          <p>
            The preview screen can display up to {{ fileDisplayLimit }} items per folder. Any
            sorting selections will apply to those {{ fileDisplayLimit }} items only. To review
            all of your project's contents, download the complete list of files.
          </p>
        </div>
      </div>
      <div class="spacer"></div>
    </div>
    <div class="table files-viewer">
      <div class="file-frame">
        <div class="file-browser">
          <table class="file-table">
            <thead>
              <tr class="file-browser-header">
                <th class="sorting col1 file-header">File Name</th>
                <th class="file-header">Modified Date</th>
                <th class="file-header">File Size</th>
                <th class="file-header">File Type</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="displayedFiles.length === 0" class="content">
                <td colspan="3" style="text-align: center">
                  <div class="startup-image">
                    <img :src="'../assets/startup_image.svg'" />
                  </div>
                  <p class="empty-dir-text">This folder is empty</p>
                </td>
              </tr>
              <tr
                class="file-browser-row"
                :class="{ loading: isLoadingFiles }"
                @mousedown="onClickRow(file)"
                v-for="(file, i) in displayedFiles"
                :key="i"
              >
                <td
                  v-if="file.collection"
                  class="browser-collection col1 file-data"
                  @mousedown="onClickCollection(file)"
                >
                  {{ file.name }}
                </td>
                <td v-else class="browser-file col1 file-data">{{ file.name }}</td>
                <td class="file-data">{{ file.last_modified }}</td>
                <td v-if="file.collection" class="file-data">--</td>
                <td v-else class="file-data">{{ file.size }}</td>
                <td class="file-data">{{ file.type }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <slot></slot>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted } from 'vue';
import CopyPath from './copy_path.vue';
import ExclamationTriangle from './exclamation_triangle.vue';
import { ProjectComponent } from '../components/Project.ts';
import HomeIcon from './home_icon.vue';

defineOptions({ name: 'FileBrowser' });
const props = defineProps({
  /**
   * The available files in the current folder.
   * An array of objects with a name, path and collection indicator, size and last modified date.
   */
  files: {
    type: Array,
    required: true,
  },
  /**
   * the current path of the files we are browsing
   */
  currentPath: {
    type: String,
    required: true,
  },
  /**
   * the current path and id of the files we are browsing
   */
  currentCollection: {
    type: Object,
    required: true,
  },
  /**
   * the hidden root path for mediaflux
   */
  hiddenRoot: {
    type: String,
    required: false,
    default: '/princeton',
  },
  /**
   * the url to query for the next directory level
   */
  directoryListUrl: {
    type: String,
    required: true,
  },

  fileDisplayLimit: {
    type: Number,
    required: true,
  },
});

const displayedFiles = ref(props.files);
const displayedPath = ref(props.currentPath);
const displayedFolders = ref([JSON.parse(props.currentCollection)]);
const hiddenRoot = ref(props.hiddenRoot);
const isLoadingFiles = ref(false);
const displayWarning = ref(props.files.length > props.fileDisplayLimit);

async function loadFiles(pathId) {
  const result = await fetch(`${props.directoryListUrl}?pathid=${pathId}`);
  const json = await result.json();
  displayWarning.value = !json.complete;
  return json.files || [];
}

async function onClickRow(file) {
  await ProjectComponent.dispatchProjectStateChange(file);
}

async function onClickCollection(file) {
  isLoadingFiles.value = true;
  displayedFiles.value = await loadFiles(file.id);
  displayedPath.value = file.path.replace(hiddenRoot.value, '');
  displayedFolders.value.push({ id: file.id, path: file.path, name: file.name });
  isLoadingFiles.value = false;
  if (displayedFiles.value.length > 0) {
    await ProjectComponent.dispatchProjectStateChange(displayedFiles.value[0]);
  }
}

async function onClickBreadcrumb(path) {
  isLoadingFiles.value = true;
  displayedFiles.value = await loadFiles(path.id);
  const pathIndex = displayedFolders.value.indexOf(path);
  displayedFolders.value = displayedFolders.value.slice(0, pathIndex + 1);
  isLoadingFiles.value = false;
}

onMounted(async () => {
  if (props.files.length > 0) {
    await ProjectComponent.dispatchProjectStateChange(props.files[0]);
  }
});
</script>
<style>
@import 'variables.css';

.file-browser-container {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  align-items: stretch;
}

.browser-collection {
  text-decoration: underline;
}

.loading {
  opacity: 0.5;
  background-color: gray;
}

.home-icon {
  flex-basis: 1.25rem;
  flex-grow: 0;
  flex-shrink: 0;
}

.breadcrumb-container {
  display: inline-flex;
  gap: 0.62rem;
  align-items: center;
}

.sizer {
  vertical-align: bottom;
}

.breadcrumb-list {
  display: flex;
  width: auto;
  height: 1.8125rem;
  gap: 0.625rem;
  margin-bottom: 0;

  list-style-type: none;
  padding: 0px;
  align-items: center;

  li:not(:last-child)::after {
    content: '/';
    margin-left: 0.62rem;
  }
  li:last-child {
    color: #717171;
  }
  li:hover {
    color: #000000;
    cursor: pointer;
  }
}

.empty-dir-text {
  color: #717171;
  font-size: 1.5em;
}

.file-frame {
  display: flex;
  flex-direction: column;
  flex-grow: 3;
  align-items: center;
  gap: 1.875rem;
}

.file-browser {
  display: flex;
  align-items: flex-start;
  gap: 3.6875rem;
  align-self: stretch;
  border-radius: 0.5rem 0.5rem 0 0;
  border: 1px solid #d0d0d0;
  border-bottom: none;
  overflow: hidden;

  .file-table {
    border-collapse: collapse;
    width: 100%;
  }

  .file-data.col1,
  .file-header.col1 {
    padding-left: 1rem;
    width: 40%;
  }

  .file-browser-header,
  .file-browser-row {
    height: 2.9375rem;
    align-items: center;
    border-bottom: 1px solid #d0d0d0;
  }

  .file-browser-row {
    background: #fff;
  }

  .file-browser-header {
    background: #f7f7f7;
  }
  .file-data,
  .file-header {
    padding-left: 0.625rem;
    flex-shrink: 0;
  }
}

.files-viewer {
  display: flex;
  align-items: flex-start;
  gap: 3.6875rem;
  flex-shrink: 0;
  align-self: stretch;
}

.content-warning {
  color: var(--gray-100);
  background-color: var(--status-warning);

  header {
    color: var(--black);
    font-weight: 600;
  }
}

.preview-limit-frame {
  display: flex;
  gap: 3.6875rem;

  .preview-limit-warning {
    display: flex;
    flex-direction: row;
    padding: 1rem;
    align-items: flex-start;
    gap: 1rem;
    border-radius: 0.5rem;
    background: var(--Status-Warning, #fff6df);

    .warning-message {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      gap: 0.25rem;
      display: flex;

      header {
        color: var(--gray-100);
        font-family: 'Libre Franklin';
        font-size: 1rem;
        font-style: normal;
        font-weight: 700;
        line-height: normal;
      }

      p {
        color: var(--gray-100);
        font-family: 'Libre Franklin';
        font-size: 1rem;
        font-style: normal;
        font-weight: 500;
        line-height: 1.5rem; /* 150% */
      }
    }
  }

  .spacer {
    flex-basis: 270px;
    flex-grow: 0;
    flex-shrink: 0;
  }
}
</style>
