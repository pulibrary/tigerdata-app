<template>
    <button :id="buttonId" class="btn copy-paste-button-sizer copy-project-path-icon" :data-url="projectPath" title="Copy project path to the clipboard">
        <div class="pul-copy-paste-tooltip" :data-url="projectPath">
            <span id="copy-project-path-label" class="copy-project-path-label-text copy-project-path-label-normal pul-copy-paste-tooltiptext">Copy</span>
        </div>
    </button>
</template>

<script setup>
import { ref, watch } from 'vue';

defineOptions({ name: 'CopyPath' });
const props = defineProps({

  /**
   * the current path of the files we are browsing
   */
  path: {
    type: String,
    required: true,
  },

});

const projectPath = ref(props.path)
const buttonId = ref("id")
watch(() => props.path, (newValue, oldValue) => { projectPath.value = newValue});

</script>

<style>
</style>