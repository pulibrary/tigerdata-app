<template>
  <div v-if="isSupported" class="copy-box">
    <button @click="copy(projectPath)" class="sizer">
      <!-- `copied` will be reset in 3s -->
      <span v-if="!copied" class="frames"></span>
      <span v-else class="check"></span>
    </button>
  </div>
  <p v-else>Your browser does not support Clipboard API</p>
</template>

<script setup>
import { ref, watch } from 'vue';
import { useClipboard } from '@vueuse/core';

defineOptions({ name: 'CopyPath' });
const props = defineProps({
  /**
   * the current path of the files we are browsing
   */
  path: {
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

const projectPath = ref(props.path);
watch(
  () => props.path,
  (newValue) => {
    projectPath.value = newValue;
  },
);

// eslint-disable-next-line no-unused-vars
const { text, copy, copied, isSupported } = useClipboard({ copiedDuring: 3000 });
const copyIconUrl = `url(${props.copyIconUrl})`;
const copiedIconUrl = `url(${props.copiedIconUrl})`;
</script>

<style>
.frames {
  background-image: v-bind(copyIconUrl);
  width: 1rem;
  height: 1.5rem;
  background-repeat: no-repeat;
  background-position: center;
  display: flex;
}
.check {
  background-image: v-bind(copiedIconUrl);
  width: 1rem;
  height: 1.5rem;
  background-repeat: no-repeat;
  background-position: center;
  display: flex;
}
.sizer {
  border: none;
  background: #fff;
}
</style>
