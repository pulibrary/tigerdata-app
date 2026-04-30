<template class="{classNames}">
  <div v-if="isSupported" class="copy-box">
    <button
      @mouseover="isHover = true"
      @mouseleave="isHover = false"
      @click="copy(projectPath)"
      class="sizer"
    >
      <!-- `copied` will be reset in 3s -->
      <copy-icon v-if="!copied" class="frames"></copy-icon>
      <check-icon v-else class="check"></check-icon>
    </button>
  </div>
  <p v-else>Your browser does not support Clipboard API</p>
  <div v-if="isSupported" class="copy-paste-tooltip">
    <span v-if="!copied" class="tooltip-text" v-show="isHover">Copy</span>
    <span v-else class="tooltip-text" v-show="isHover">Copied</span>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import { useClipboard } from '@vueuse/core';
import CopyIcon from './copy_icon.vue';
import CheckIcon from './check_icon.vue';

defineOptions({ name: 'CopyPath' });
const props = defineProps({
  /**
   * the current path of the files we are browsing
   */
  path: {
    type: String,
    required: true,
  },

  /**
   * Additional class names to apply to the component
   */
  classNames: {
    type: Array,
    required: false,
    default: () => [],
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
const isHover = ref(false);
</script>

<style>
.frames {
  flex-basis: 1.25rem;
  flex-grow: 0;
  flex-shrink: 0;
}
.check {
  flex-basis: 1.25rem;
  flex-grow: 0;
  flex-shrink: 0;
}
.sizer {
  border: none;
  background: #fff;
  align-self: center;
}

.copy-paste-tooltip {
  position: relative;
  display: inline-block;
  cursor: pointer;
  width: 1.5rem;
  height: 1.5rem;
  aspect-ratio: 1/1;
  font-weight: normal;

  .tooltip-text {
    background-color: #333;
    color: #fff;
    font-size: 12px;
    padding: 8px 12px;
    border-radius: 4px;
    white-space: nowrap;
    text-overflow: ellipsis;
    position: absolute;
    top: -25%;
    z-index: 1; /* Ensure tooltip is displayed above content */

    &::after {
      content: ' ';
      position: absolute;
      top: 50%;
      right: 100%; /* To the left of the tooltip */
      margin-top: -5px;
      border-width: 5px;
      border-style: solid;
      border-color: transparent #333 transparent transparent;
    }
  }
}
</style>
