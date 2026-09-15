<template>
  <Select
    v-model="selected"
    :options="props.options"
    placeholder="Select Data Security Level"
  />
  <!--
  @slot hidden-input -- You can use this to pass the user's selected value back to the backend (e.g. Rails) on form submit
     @binding {string} selectedItem the item value that the user has selected
  -->
  <slot name="hidden-input" :selectedItem="selected"></slot>
</template>
<script setup lang="ts">
  import { ref } from "vue"
  import { Select }from "vue3-select-component"
  import "vue3-select-component/styles" 

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
  })
  const selected = ref(props.defaultValue);
</script>
<style scoped>

</style>