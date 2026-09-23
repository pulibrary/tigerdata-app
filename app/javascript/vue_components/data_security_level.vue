<template>
  <LuxInputSelect
    hideLabel="true"
    label="data security level"
    :value="selected"
    :options="displayedOptions"
    @change="selected = $event"
    class="data-security-level-select tigerdata-lux-select"
    name="data-security-level"
  />
  <!--
  @slot hidden-input -- You can use this to pass the user's selected value back to the backend (e.g. Rails) on form submit
     @binding {string} selectedItem the item value that the user has selected
  -->
  <slot name="hidden-input" :selectedItem="selected"></slot>
</template>
<script setup lang="ts">
import { ref } from 'vue';
import { LuxInputSelect } from 'lux-design-system';

const props = defineProps({
  /**
   * The default value for the select component.
   */
  defaultValue: {
    type: String,
    required: false,
    default: '',
  },
  options: {
    type: Array<{ value: string; label: string; disabled?: boolean }>,
    required: true,
  },
});
const selected = ref(props.defaultValue);
const displayedOptions = ref(calculateDisplayedOptions(props.options, props.defaultValue));

function calculateDisplayedOptions(
  options: Array<{ value: string; label: string; disabled?: boolean }>,
  defaultValue: string,
) {
  if (defaultValue == '') {
    options.unshift({ value: '', label: 'Select Data Security Level', disabled: true });
  }
  return options;
}
</script>
<style>
.data-security-level .data-security-level-select {
  .lux-select[value=''] {
    color: var(--neutral-darkest-gray);
    font-weight: lighter;
  }
  .lux-select {
    width: 100%;
    border-radius: 0.5rem;
  }
}
</style>
