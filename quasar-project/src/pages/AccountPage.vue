<template>
  <q-page class="q-pa-md">
    <q-card>
      <q-card-section>
        <div class="text-h6">Editar conta</div>
      </q-card-section>

      <q-card-section>
        <q-form @submit="updateName">
          <q-input v-model="user.name" label="Nome" />
          <q-btn type="submit" label="Atualizar Nome" color="primary" class="q-mt-md" />
        </q-form>

        <q-separator class="q-my-md" />

        <q-form @submit="updatePassword">
          <q-input v-model="password.current" label="Senha atual" type="password" />
          <q-input v-model="password.new" label="Nova senha" type="password" />
          <q-input v-model="password.confirm" label="Confirmar nova senha" type="password" />
          <q-btn type="submit" label="Atualizar senha" color="primary" class="q-mt-md" />
        </q-form>

        <q-separator class="q-my-md" />

        <q-btn 
          label="Excluir conta" 
          color="negative" 
          @click="confirmDelete = true" 
          class="q-mt-md" 
        />
      </q-card-section>
    </q-card>

    <q-dialog v-model="confirmDelete" persistent>
      <q-card>
        <q-card-section>
          <div class="text-h6">Confirmar exclusão</div>
          <div class="text-subtitle2">Esta ação não pode ser desfeita</div>
        </q-card-section>

        <q-card-section>
          <q-input v-model="deletePassword" label="Digite sua senha para confirmar" type="password" />
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancelar" color="primary" v-close-popup />
          <q-btn flat label="Confirmar" color="negative" @click="deleteAccount" />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { api } from 'src/boot/axios';
import { useQuasar } from 'quasar';
import { AxiosError } from 'axios';

const $q = useQuasar();

const user = ref({
  name: '',
  email: ''
});

const password = ref({
  current: '',
  new: '',
  confirm: ''
});

const deletePassword = ref('');
const confirmDelete = ref(false);

onMounted(async () => {
  try {
    const response = await api.get('/account');
    user.value = {
      name: response.data.nome,
      email: response.data.email
    };
  } catch (error) {
    console.error('Erro ao carregar dados do usuário:', error);
    $q.notify({
      type: 'negative',
      message: 'Erro ao carregar dados do usuário'
    });
  }
});

async function updateName() {
  try {
    await api.put('/account/name', { newName: user.value.name });
    $q.notify({
      type: 'positive',
      message: 'Nome atualizado com sucesso!'
    });
  } catch (error) {
    console.error('Erro ao atualizar nome:', error);
    const errorMessage = error instanceof AxiosError 
      ? error.response?.data?.message || 'Erro ao atualizar nome'
      : 'Erro ao atualizar nome';
    
    $q.notify({
      type: 'negative',
      message: errorMessage
    });
  }
}

async function updatePassword() {
  if (password.value.new !== password.value.confirm) {
    $q.notify({
      type: 'negative',
      message: 'As senhas não coincidem'
    });
    return;
  }

  try {
    await api.put('/account/password', {
      currentPassword: password.value.current,
      newPassword: password.value.new
    });
    
    $q.notify({
      type: 'positive',
      message: 'Senha atualizada com sucesso!'
    });
    
    // limpar os campos
    password.value = {
      current: '',
      new: '',
      confirm: ''
    };
  } catch (error) {
    console.error('Erro ao atualizar senha:', error);
    const errorMessage = error instanceof AxiosError 
      ? error.response?.data?.message || 'Erro ao atualizar senha'
      : 'Erro ao atualizar senha';
    
    $q.notify({
      type: 'negative',
      message: errorMessage
    });
  }
}

async function deleteAccount() {
  try {
    await api.delete('/account', { data: deletePassword.value });
    $q.notify({
      type: 'positive',
      message: 'Conta excluída com sucesso!'
    });
    // redirecionar para a página de login ou home
    window.location.href = '/';
  } catch (error) {
    console.error('Erro ao excluir conta:', error);
    const errorMessage = error instanceof AxiosError 
      ? error.response?.data?.message || 'Erro ao excluir conta'
      : 'Erro ao excluir conta';
    
    $q.notify({
      type: 'negative',
      message: errorMessage
    });
    confirmDelete.value = false;
  }
}
</script>
