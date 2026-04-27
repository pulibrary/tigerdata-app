<template>
  <div
    class="content-warning container-inline p-3"
    v-if="displayedFiles.length >= fileDisplayLimit"
  >
    <div class="row">
      <div class="col-auto mx-3 my-1">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="32"
          height="32"
          fill="currentColor"
          class="bi bi-exclamation-triangle-fill"
          viewBox="0 0 16 16"
        >
          <path
            d="M8.982 1.566a1.13 1.13 0 0 0-1.96 0L.165 13.233c-.457.778.091 1.767.98 1.767h13.713c.889 0 1.438-.99.98-1.767zM8 5c.535 0 .954.462.9.995l-.35 3.507a.552.552 0 0 1-1.1 0L7.1 5.995A.905.905 0 0 1 8 5m.002 6a1 1 0 1 1 0 2 1 1 0 0 1 0-2"
          />
        </svg>
      </div>
      <div class="col mx-3">
        <header>Preview Limit Reached</header>
        <p>
          The preview screen can display up to {{ fileDisplayLimit }} items per folder. Any
          sorting selections will apply to those {{ fileDisplayLimit }} items only. To review
          all of your project's contents, download the complete list of files.
        </p>
      </div>
    </div>
  </div>

  <div class="breadcrumb-container row">
    <div class="home-icon-image col-auto">
      <img :src="'../assets/home_icon.svg'" />
    </div>
    <ol class="breadcrumb-list col-auto">
      <li v-for="(path, i) in displayedFolders" @mousedown="onClickBreadcrumb(path)">
        {{ path.name }}
      </li>
    </ol>
    <copy-path
      class="col"
      :path="displayedPath"
      :copyIconUrl="copyIconUrl"
      :copiedIconUrl="copiedIconUrl"
    >
    </copy-path>
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
</template>
<script setup>
import { ref, onMounted } from 'vue';
import CopyPath from './copy_path.vue';
import { ProjectComponent } from '../components/Project.ts';

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

  copyIconUrl: {
    type: String,
    required: true,
  },

  copiedIconUrl: {
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
const copyIconUrl = ref(props.copyIconUrl);
const copiedIconUrl = ref(props.copiedIconUrl);

async function loadFiles(pathId) {
  const result = await fetch(`${props.directoryListUrl}?pathid=${pathId}`);
  const json = await result.json();
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
.browser-collection {
  text-decoration: underline;
}

.loading {
  opacity: 0.5;
  background-color: gray;
}

.home-icon-image {
  margin-left: 0.2rem;
}

.breadcrumb-container {
  display: inline-flex;
  gap: 0.62rem;
}

.breadcrumb-list {
  display: flex;
  width: auto;
  height: 1.8125rem;
  align-items: center;
  gap: 0.625rem;

  list-style-type: none;
  padding: 0px;
  display: flex;
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
</style>
