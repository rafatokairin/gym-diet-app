<template>
  <div class="q-pa-md flex flex-center" style="min-height: 100vh; background-color: #f5f5f5;">
    <q-card class="q-pa-xl shadow-2" style="width: 100%; max-width: 400px;">
      <q-card-section class="text-center q-mb-md">
        <div class="text-h5 text-primary">Cadastro</div>
        <div class="text-subtitle2 text-grey">Crie sua conta</div>
      </q-card-section>

      <q-card-section class="q-gutter-md">
        <q-input filled v-model="name" label="Nome" dense />
        <q-input filled v-model="email" label="Email" type="email" dense />
        <q-input filled v-model="password" label="Senha" type="password" dense />
        <q-input filled v-model="confirmPassword" label="Confirmar Senha" type="password" dense />
      </q-card-section>

      <q-card-actions class="q-pt-sm column q-gutter-sm">
        <q-btn
          label="Cadastrar"
          color="primary"
          class="full-width"
          unelevated
          @click="register"
        />
        <q-btn
          label="Já tem uma conta?"
          flat
          class="full-width text-primary"
          @click="goToLogin"
        />
      </q-card-actions>
    </q-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from 'boot/axios'
import type { AxiosError } from 'axios'
import { Notify } from 'quasar'

const name = ref<string>('')
const email = ref<string>('')
const password = ref<string>('')
const confirmPassword = ref<string>('')
const isLoading = ref<boolean>(false) // adicionado estado de loading
const router = useRouter()

const showError = (message: string) => {
  Notify.create({
    type: 'negative',
    message,
    position: 'top',
    timeout: 3000,
    actions: [{ icon: 'close', color: 'white' }]
  })
}

const validateForm = (): boolean => {
  if (!name.value || !email.value || !password.value || !confirmPassword.value) {
    Notify.create({ 
      type: 'negative', 
      message: 'Preencha todos os campos.',
      position: 'top'
    })
    return false
  }

  if (password.value !== confirmPassword.value) {
    Notify.create({ 
      type: 'negative', 
      message: 'As senhas não coincidem.',
      position: 'top'
    })
    return false
  }

  if (password.value.length < 6) {
    Notify.create({
      type: 'negative',
      message: 'A senha deve ter pelo menos 6 caracteres.',
      position: 'top'
    })
    return false
  }

  // validação simples de email
  if (!/^\S+@\S+\.\S+$/.test(email.value)) {
    Notify.create({
      type: 'negative',
      message: 'Por favor, insira um email válido.',
      position: 'top'
    })
    return false
  }

  return true
}

const register = async () => {
  if (!validateForm()) return

  isLoading.value = true

  try {
    const response = await api.post('/auth/register', {
      nome: name.value,
      email: email.value,
      senha: password.value,
    })

    if (response.status >= 200 && response.status < 300) {
      Notify.create({
        type: 'positive',
        message: 'Cadastro realizado com sucesso!',
        position: 'top',
        timeout: 1000
      })

      await new Promise(resolve => setTimeout(resolve, 1200))
      
      try {
        await router.push('/login')
      } catch (routerError) {
        console.error('Erro no redirecionamento:', routerError)
        window.location.href = '/login'
      }
    } else {
      showError('O cadastro foi realizado, mas houve uma resposta inesperada.')
    }
  } catch (e: unknown) {
    const err = e as AxiosError
    
    if (err.response) {
      if (err.response.status === 400 || err.response.status === 409) {
        showError('Email já cadastrado. Por favor, use outro email ou faça login.')
      } else {
        showError('Erro no servidor. Por favor, tente novamente mais tarde.')
      }
    } else {
      showError('Erro de conexão. Verifique sua internet e tente novamente.')
    }
    
    console.error('Erro no registro:', err)
  } finally {
    isLoading.value = false
  }
}

const goToLogin = async () => {
  await router.push('/login')
}
</script>
