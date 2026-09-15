<template>
  <Select
    v-model="selected"
    :options="props.options"
    placeholder="Select Data Security Level"
    class="security-level-select"
  />
  <!--
  @slot hidden-input -- You can use this to pass the user's selected value back to the backend (e.g. Rails) on form submit
     @binding {string} selectedItem the item value that the user has selected
  -->
  <slot name="hidden-input" :selectedItem="selected"></slot>
</template>
<script setup lang="ts">
import { ref } from 'vue';
import { Select } from 'vue3-select-component';
import 'vue3-select-component/styles';

const props = defineProps({
  /**
   * The default value for the select component.
   */
  defaultValue: {
    type: String,
    required: false,
    default: null,
  },
  options: {
    type: Array,
    required: true,
  },
});
const selected = ref(props.defaultValue);
</script>
<style>
.security-level-select {
  --vs-border-radius: 0.5rem;
  --vs-outline-color: #d0d0d0;
  --vs-text-color: #121212;
  --vs-placeholder-color: #717171;
}

#v1-select-1-listbox {
  display: flex;
  padding: 0.5rem;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
}

#select-option-1,
#select-option-2,
#select-option-3,
#select-option-4 {
  --vs-option-hover-background-color: #d0d0d0;
  --vs-option-focused-background-color: #d0d0d0;
  --vs-option-selected-background-color: #fae3cc;
  border-radius: 0.25rem;
  padding: 0.25rem 0.5rem;
}

#select-option-1,
#select-option-2 {
  color: #121212;
}
#select-option-3,
#select-option-4 {
  background-color: #eee;
  color: #717171;
}
</style>
