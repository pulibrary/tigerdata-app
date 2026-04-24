<template>
  <section class="project-file col mx-2 card sticky">
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
import { onMounted } from 'vue';
import { ProjectComponent } from './../components/Project.ts';

defineOptions({ name: 'Project' });

onMounted(() => {
  ProjectComponent.bind(window);
});
</script>
