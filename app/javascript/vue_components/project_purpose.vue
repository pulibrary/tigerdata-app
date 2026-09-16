<template>
  <Select
    v-model="selected"
    :options="props.options"
    placeholder="Select Project Purpose"
    class="request-select project-purpose-select"
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

defineOptions({ name: 'ProjectPurpose' });

const props = defineProps({
  /**
   * The default value for the select component.
   */
  defaultValue: {
    type: String,
    required: false,
    default: null,
  },
  /**
   * The options for the select component. in the format of [{ value: 'value1', label: 'Label 1' }, { value: 'value2', label: 'Label 2' }]
   */
  options: {
    type: Array,
    required: true,
  },
});
const selected = ref(props.defaultValue);

function selectDefault() {
  return displayedObject.value.created_by?.uid == 'manager';
}
</script>
<style>
@import 'select.css';
</style>
