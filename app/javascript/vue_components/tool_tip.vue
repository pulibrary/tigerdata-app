<template>
  <div
    tabindex="0"
    class="tooltip-container"
    @click="isHover = !isHover"
    @keypress.enter="isHover = !isHover"
    @mouseleave="isHover = false"
  >
    <info-icon></info-icon>
    <span class="tooltiptext" v-show="isHover">{{ tooltip }}</span>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import infoIcon from './icons/info_icon.vue';

defineOptions({ name: 'CopyPath' });
const props = defineProps({
  /**
   * the current path of the files we are browsing
   */
  text: {
    type: String,
    required: true,
  },
});

const tooltip = ref(props.text);

const isHover = ref(false);
</script>

<style>
.tooltip-container {
  display: flex;
  align-items: center;
  padding-left: 0.25rem;
  position: relative;
}

/* Tooltip text */
.tooltiptext::after {
  content: ' ';
  position: absolute;
  margin-top: -5px;
  border-width: 5px;
  border-style: solid;
  right: 100%;
  top: 50%;
  border-color: transparent #333 transparent transparent;
}

.tooltiptext {
  width: 8rem;
  height: fit-content;
  background-color: #333;
  color: #fff;
  font-size: 12px;
  padding: 8px 12px;
  border-radius: 4px;
  white-space: nowrap;
  text-overflow: ellipsis;
  position: absolute;
  z-index: 1; /* Ensure tooltip is displayed above content */
  left: 120%;
  @supports (-webkit-line-clamp: 4) {
    white-space: initial;
    display: -webkit-box;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 10;
  }
}
</style>
