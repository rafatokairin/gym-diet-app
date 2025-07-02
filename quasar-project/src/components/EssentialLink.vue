<template>
  <q-item clickable @click="handleClick" exact>
    <q-item-section v-if="icon" avatar>
      <q-icon :name="icon" />
    </q-item-section>

    <q-item-section>
      <q-item-label>{{ title }}</q-item-label>
      <q-item-label caption>{{ caption }}</q-item-label>
    </q-item-section>
  </q-item>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'

export interface EssentialLinkProps {
  title: string
  caption?: string
  link?: string
  icon?: string
  action?: () => void
}

const props = defineProps<EssentialLinkProps>()
const router = useRouter()

function handleClick () {
  if (props.action) {
    props.action()
  } else if (props.link) {
    void router.push(props.link)
  }
}
</script>