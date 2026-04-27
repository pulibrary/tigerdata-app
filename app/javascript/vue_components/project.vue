<template>
  <section class="project-file card sticky">
    <div class="card-body rounded">
      <header class="card-title lead fw-bold px-2 my-0">Details</header>
      <div class="project-file-details inline-container bg-body rounded p-2">
        <div class="inline-container">
          <header class="fw-semibold" data-attribute-name="fileName">File Name</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="fileName"></p>
        </div>
        <div class="inline-container">
          <header class="fw-semibold" data-attribute-name="fileSize">File Size</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="fileSize"></p>
        </div>
        <div class="inline-container">
          <header class="fw-semibold" data-attribute-name="fileType">File Type</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="fileType"></p>
        </div>
        <div class="inline-container">
          <header class="fw-semibold" data-attribute-name="location">Location</header>
          <div class="row">
            <copy-path
            class="col"
            :path="displayedPath"
            :copyIconUrl="copyIconUrl"
            :copiedIconUrl="copiedIconUrl"
            >
            </copy-path>
          </div>
          <p class="project-file-attribute font-monospace" data-attribute-name="location"></p>
        </div>
        <div class="inline-container">
          <header class="fw-semibold" data-attribute-name="modifiedDate">Modified Date</header>
          <p
            class="project-file-attribute font-monospace"
            data-attribute-name="modifiedDate"
          ></p>
        </div>
      </div>
    </div>
  </section>
</template>
<script setup>
import { ref, onMounted, watch } from 'vue';
import CopyPath from './copy_path.vue';
import { ProjectComponent } from '../components/Project.ts';

defineOptions({ name: 'Project' });
const props = defineProps({
  /**
   * the current path of the files we are browsing
   */
  currentPath: {
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
});
const displayedPath = ref(props.currentPath);
const copyIconUrl = ref(props.copyIconUrl);
const copiedIconUrl = ref(props.copiedIconUrl);
// const attrName = ref("data-attribute-name");
// const location = ref("location");

// watch for changes in the location and update the displayed path accordingly
// watch(
//   () => attrName.value,
//   (newValue) => {
//     displayedPath.value = newValue;
//   },
// );

onMounted(() => {
  ProjectComponent.bind(window);
});
</script>
<style>
.card {
  height: fit-content !important;
  border: none !important;
}

.sticky {
  position: sticky !important;
  overflow: auto !important;
  top: 10px !important;
}

.project-file {
  display: flex;
  width: 16.875rem;
  flex-direction: column;
  align-items: flex-start;
  flex-grow: 0;
  gap: -0.5rem;

  .card-body {
    width: 100%;
  }

  .card-title {
    font-size: 1.125rem;
    font-weight: bold !important;
    line-height: 1.75rem;
    letter-spacing: -0.03125rem;
  }

  header {
    font-size: 0.875rem;
    font-weight: bold !important;
    line-height: 0.875rem;
  }

  .project-file-attribute {
    font-family: 'Libre Franklin', sans-serif !important;
    font-size: 0.875rem;
  }
}
</style>
