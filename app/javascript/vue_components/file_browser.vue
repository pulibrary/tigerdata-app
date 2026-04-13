<template>
  <div class="file-browser">
    {{ displayedPath }}
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
</template>
<script setup>
import { ref } from 'vue';

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

const displayedFiles = ref(props.files);
const displayedPath = ref(props.currentPath);
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
</style>
