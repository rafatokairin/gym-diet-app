<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated>
      <q-toolbar>
        <q-btn
          flat
          dense
          round
          icon="menu"
          aria-label="Menu"
          @click="toggleLeftDrawer"
        />

        <q-toolbar-title>
          Rafa Lift
        </q-toolbar-title>

        <div class="q-pa-md">
          <q-toggle 
            v-model="isDarkMode" 
            color="black"
            keep-color label="Dark Mode"
          />
        </div>
      </q-toolbar>

      <!-- tabs (treino - dieta) -->
      <q-tabs
        v-model="tab"
        inline-label
        align="left"
        class="bg-blue-4 text-white shadow-2 justify-start"
      >
        <!-- q-route-tab (routing) -->
        <q-route-tab name="index" icon="home" label="Home" to="/index" />
        <q-route-tab name="workouts" icon="fitness_center" label="Workouts" to="/workouts" />
        <q-route-tab name="diets" icon="restaurant" label="Diets" to="/diets" />
      </q-tabs>
    </q-header>

    <q-drawer
      v-model="leftDrawerOpen"
      show-if-above
      bordered
    >
      <q-list>
        <q-item-label
          header
        >
          Sistema
        </q-item-label>

        <EssentialLink
          v-for="link in linksList"
          :key="link.title"
          v-bind="link"
        />
      </q-list>
    </q-drawer>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router'          // ← import do router
import EssentialLink, { type EssentialLinkProps } from 'components/EssentialLink.vue'
import { api } from 'boot/axios'                // ← sua instância comCredentials

const router = useRouter()
const leftDrawerOpen = ref(false)
function toggleLeftDrawer () {
  leftDrawerOpen.value = !leftDrawerOpen.value
}

// dark mode
import { useQuasar } from 'quasar'
const $q = useQuasar()
const isDarkMode = ref($q.dark.isActive)
watch(isDarkMode, val => $q.dark.set(val))

const tab = ref('mails')

// monta a lista com o item de Logout chamando o endpoint
const linksList: EssentialLinkProps[] = [
  {
    title: 'Conta',
    caption: 'Editar conta',
    icon: 'account_circle',
    link: '/account'
  },
  {
    title: 'Logout',
    caption: 'Sair',
    icon: 'logout',
    action: async () => {
      try {
        // chama o logout no servidor — ele vai expirar o cookie jwt
        await api.post('/auth/logout')
      }
      catch (e) {
        console.warn('Erro ao deslogar:', e)
      }
      // garante que qualquer header antigo seja removido (caso você tenha setado)
      delete api.defaults.headers.common['Authorization']

      // redireciona pra página de login
      await router.push('/login')
    }
  }
]
</script>
