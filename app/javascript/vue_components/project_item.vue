<template>
  <section class="project-file card sticky">
    <div class="full-width">
      <header class="card-title lead fw-bold px-2 my-0">Details</header>
      <div class="project-file-details inline-container bg-body rounded p-2">
        <div class="inline-container">
          <header
            v-if="displayedObject.collection"
            class="fw-semibold"
            data-attribute-name="fileName"
          >
            Folder Name
          </header>
          <header v-else class="fw-semibold" data-attribute-name="fileName">File Name</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="fileName">
            {{ displayedObject.name }}
          </p>
        </div>
        <div v-if="displayedObject.collection" class="inline-container">
          <header class="fw-semibold" data-attribute-name="folderSize">Folder Size</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="folderSize">
            {{ displayedObject.folder_size }}
          </p>
        </div>
        <div v-else class="inline-container">
          <header class="fw-semibold" data-attribute-name="fileSize">File Size</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="fileSize">
            {{ displayedObject.size }}
          </p>
        </div>
        <div v-if="displayedObject.collection" class="inline-container">
          <header class="fw-semibold" data-attribute-name="itemCount">Item Count</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="itemCount">
            {{ displayedObject.asset_count }}
          </p>
        </div>
        <div v-if="!displayedObject.collection" class="inline-container">
          <header class="fw-semibold" data-attribute-name="fileType">File Type</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="fileType">
            {{ displayedObject.type }}
          </p>
        </div>
        <div class="inline-container">
          <div class="location-container">
            <header class="fw-semibold" data-attribute-name="location">Location</header>
            <copy-path class="col" :path="displayedPath"> {{ displayedPath }}</copy-path>
          </div>
          <p
            class="project-file-attribute font-monospace"
            ref="locationRef"
            data-attribute-name="location"
          >
            {{ displayedPath }}
          </p>
        </div>
        <div class="inline-container">
          <header class="fw-semibold" data-attribute-name="modifiedDate">Modified Date</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="modifiedDate">
            {{ displayedObject.last_modified }}
          </p>
        </div>
        <div class="inline-container">
          <header class="fw-semibold" data-attribute-name="createdDate">Created Date</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="createdDate">
            {{ displayedObject.created_on }}
          </p>
        </div>
        <div class="inline-container">
          <header class="fw-semibold" data-attribute-name="createdBy">Created By</header>
          <p class="project-file-attribute font-monospace" data-attribute-name="createdBy">
            {{ displayedObject.created_by }}
          </p>
        </div>
      </div>
    </div>
  </section>
</template>
<script setup>
import { ref, watch } from 'vue';
import CopyPath from './copy_path.vue';

defineOptions({ name: 'ProjectItem' });
const props = defineProps({
  currentObject: {
    type: Object,
    required: true,
  },
  hiddenRoot: {
    type: String,
    required: false,
    default: '/princeton',
  },
});

const hiddenRoot = ref(props.hiddenRoot);
const displayedPath = ref(props.currentObject.path.replace(hiddenRoot.value, ''));
const displayedObject = ref(props.currentObject);

watch(
  () => props.currentObject,
  (newValue) => {
    displayedObject.value = newValue;
    displayedPath.value = newValue.path.replace(hiddenRoot.value, '');
  },
);
</script>
<style>
.card {
  height: fit-content !important;
  border: none !important;
  @media (max-width: 744px) {
    display: none !important;
  }
}

.sticky {
  position: sticky !important;
  overflow: auto !important;
  top: 10px !important;
}

.location-container {
  display: inline-flex;
  justify-content: center;
  align-items: center;
  .copy-box {
    padding-top: 0.25rem;
  }
}
.project-file {
  display: flex;
  width: 16.875rem;
  flex-direction: column;
  align-items: flex-start;
  flex-grow: 0;
  padding: 0.625rem 1rem;
  align-items: center;
  gap: 0.625rem;
  align-self: stretch;
  border-radius: 0.5rem 0.5rem 0 0;
  background: #eee;

  .full-width {
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
    line-break: anywhere;
  }
}
</style>
