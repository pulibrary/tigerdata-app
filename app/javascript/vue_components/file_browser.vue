<template>
  <div class="breadcrumb-container">
    <div class="home-icon-image">
      <img :src="'../assets/home_icon.svg'">
    </div>
    <ol class="breadcrumb-list">
      <li v-for="(path, i) in displayedFolders" @mousedown="onClickBreadcrumb(path)">
        {{ path.name }}
      </li>
    </ol>
    <copy-path :path="displayedPath"> </copy-path>
  </div>
  <div class="table project-files">
  <div class="file-browser">
    <table class="project-contents">
      <thead>
        <tr class="content heading">
          <th class="sorting">name</th>
          <th>size</th>
          <th>last updated</th>
        </tr>
      </thead>
      <tbody>
        <tr
          class="content"
          :class="{ loading: isLoadingFiles }"
          v-for="(file, i) in displayedFiles"
          :key="i"
        >
          <td
            v-if="file.collection"
            class="browser-collection"
            @mousedown="onClickCollection(file)"
          >
            {{ file.name }}
          </td>
          <td v-else class="browser-file">{{ file.name }}</td>
          <td v-if="file.collection">--</td>
          <td v-else>{{ file.size }}</td>
          <td>{{ file.last_modified }}</td>
        </tr>
      </tbody>
    </table>
  </div>
  </div>
</template>
<script setup>
import { ref } from 'vue';
import CopyPath from "./copy_path.vue"

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
});
function splitPaths(displayedPath){
return displayedPath.split("/");
}

const displayedFiles = ref(props.files);
const displayedPath = ref(props.currentPath);
const displayedFolders = ref([JSON.parse(props.currentCollection)]);
const hiddenRoot = ref(props.hiddenRoot);
const isLoadingFiles = ref(false);

async function loadFiles(pathId) {
  const result = await fetch(`${props.directoryListUrl}?pathid=${pathId}`);
  const json = await result.json();
  return json.files || [];
}

async function onClickCollection(file) {
  isLoadingFiles.value = true;
  displayedFiles.value = await loadFiles(file.id);
  displayedPath.value = file.path.replace(hiddenRoot.value, '');
  displayedFolders.value.push({id: file.id, path: file.path, name: file.name});
  isLoadingFiles.value = false;
}

async function onClickBreadcrumb(path) {
  isLoadingFiles.value = true;
  displayedFiles.value = await loadFiles(path.id);
  const path_index = displayedFolders.value.indexOf(path);
  displayedFolders.value = displayedFolders.value.slice(0,path_index+1);
  isLoadingFiles.value = false;
}
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
  content: "/";
  margin-left: 0.62rem;

 }
 li:last-child {
  color: #717171
 }
 li:hover {
  color: #000000;
  cursor: pointer;
 }
}
.copy-button {
  background-image: asset_url("copy.svg");
}
</style>
