<template>
  <div class="q-pa-md flex flex-center" style="min-height: 100vh; background-color: #f5f5f5;">
    <q-card class="q-pa-xl shadow-2" style="width: 100%; max-width: 400px;">
      <q-card-section class="text-center q-mb-md">
        <div class="text-h5 text-primary">Login</div>
        <div class="text-subtitle2 text-grey">Acesse sua conta</div>
      </q-card-section>
      <q-card-section class="q-gutter-md">
        <q-input filled v-model="email" label="Email" type="email" dense />
        <q-input filled v-model="password" label="Senha" type="password" dense />
      </q-card-section>
      <q-card-actions class="q-pt-sm column q-gutter-sm">
        <q-btn label="Entrar" color="primary" class="full-width" unelevated @click="login" />
        <q-btn label="Cadastrar" flat class="full-width text-primary" @click="goToRegister" />
      </q-card-actions>
    </q-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from 'boot/axios'
import type { AxiosError } from 'axios'

const email = ref('')
const password = ref('')
const router = useRouter()

const login = async () => {
  if (!email.value || !password.value) return;

  try {
    await api.post('/auth/login', {
      login: email.value,
      password: password.value
    })

    await router.push('/index')
  } catch (err: unknown) {
    if ((err as AxiosError).isAxiosError) {
      console.error('Erro no login:', (err as AxiosError).response?.data || (err as AxiosError).message)
    } else if (err instanceof Error) {
      console.error('Erro no login:', err.message)
    } else {
      console.error('Erro desconhecido no login:', err)
    }
  }
}

// marca como async e await, para não deixar promise “flutuando”
const goToRegister = async () => {
  await router.push('/register')
}
</script>
