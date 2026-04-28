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
          <div class="location-container">
            <header class="fw-semibold" data-attribute-name="location">Location</header>
            <copy-path
              class="col"
              :path="displayedPath"
              :copyIconUrl="copyIconUrl"
              :copiedIconUrl="copiedIconUrl"
            >
            </copy-path>
          </div>
          <p class="project-file-attribute font-monospace" ref="locationRef" data-attribute-name="location"></p>
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
import { ref, onMounted, watch, onUnmounted } from 'vue';
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
  hiddenRoot: {
    type: String,
    required: false,
    default: '/princeton',
  },
});

const displayedPath = ref(props.currentPath);
displayedPath.value = props.currentPath.replace(props.hiddenRoot, '');
const copyIconUrl = ref(props.copyIconUrl);
const copiedIconUrl = ref(props.copiedIconUrl);
const hiddenRoot = ref(props.hiddenRoot);

// setup a mutation observer to watch for changes to the location element in the project details and update the displayed path accordingly
const locationRef = ref(null)
let observer = null

onMounted(() => {
  ProjectComponent.bind(window);

  observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      console.log('DOM text changed!', mutation.target.textContent)
      displayedPath.value = mutation.target.textContent.replace(hiddenRoot.value, '');
    })
  })

  observer.observe(locationRef.value, {
    characterData: true,
    childList: true,
  })
});

onUnmounted(() => observer.disconnect())
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
