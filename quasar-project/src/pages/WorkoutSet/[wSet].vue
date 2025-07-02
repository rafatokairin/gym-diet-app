<template>
    <div>
      <ErrorNotFound v-if="!isValidSet" />
      <q-page v-else class="q-pa-md">
        <div class="q-pa-md">
          <q-btn
            push
            class="full-width q-pa-lg"
            color="pink"
            label="Adicionar exercício"
            @click="openAddDialog"
          />
        </div>
  
        <!-- Diálogo para adicionar/editar exercício -->
        <q-dialog v-model="showDialog">
          <q-card class="q-pa-md" style="min-width: 400px">
            <q-card-section>
              <div class="text-h6">
                {{ isEditing ? 'Editar exercício' : 'Novo exercício' }}
              </div>
            </q-card-section>
  
            <q-card-section>
            <q-input v-model="form.grupo_muscular" label="Grupo Muscular" />

              <q-input v-model="form.nome" label="Nome do exercício" />
              <q-input v-model.number="form.series" type="number" label="Séries" />
              <q-input v-model.number="form.repeticoes" type="number" label="Repetições" />
              <q-input v-model.number="form.peso" type="number" label="Peso (kg)" />
              <q-input v-model.number="form.tempo" type="number" label="Tempo (segundos)" />
            </q-card-section>
  
            <q-card-actions align="right">
              <q-btn flat label="Cancelar" v-close-popup @click="resetForm" />
              <q-btn
                :label="isEditing ? 'Salvar' : 'Adicionar'"
                color="primary"
                @click="submitForm"
                :disable="!form.nome"
              />
            </q-card-actions>
          </q-card>
        </q-dialog>
  
        <div class="q-pa-md">
          <q-table
            flat bordered
            :title="`Treino ${displaySet}`"
            :rows="rows"
            :columns="columns"
            row-key="id"
            virtual-scroll
            v-model:pagination="pagination"
            :rows-per-page-options="[0]"
            style="height: 560px"
          >
            <template v-slot:body="props">
              <q-tr :props="props">
                <q-td key="grupo_muscular" :props="props">{{ props.row.grupo_muscular }}</q-td>
                <q-td key="nome" :props="props">{{ props.row.nome }}</q-td>
                <q-td key="series" :props="props"><q-badge color="green">{{ props.row.series }}</q-badge></q-td>
                <q-td key="repeticoes" :props="props"><q-badge color="blue">{{ props.row.repeticoes }}</q-badge></q-td>
                <q-td key="peso" :props="props"><q-badge color="purple">{{ props.row.peso }}</q-badge></q-td>
                <q-td key="tempo" :props="props"><q-badge color="orange">{{ props.row.tempo }}</q-badge></q-td>
                <q-td key="actions" :props="props">
                  <q-btn dense flat icon="edit" color="primary" @click="startEdit(props.row)" />
                  <q-btn dense flat icon="delete" color="negative" @click="deleteExercise(props.row.id)" />
                </q-td>
              </q-tr>
            </template>
          </q-table>
        </div>
      </q-page>
    </div>
  </template>
  
  <script setup lang="ts">
  import { useRoute } from 'vue-router'
  import { ref, computed, onMounted, watch } from 'vue'
  import { api } from 'boot/axios'
  import type { AxiosError } from 'axios'
  import ErrorNotFound from 'pages/ErrorNotFound.vue'
  
  // Parâmetros da rota
  const route = useRoute()
  const rawSet = route.params.wSet as string
  const displaySet = computed(() => rawSet)
  
  // Conjuntos válidos
  const validSets = ['A', 'B', 'C', 'D', 'E']
  const isValidSet = computed(() => validSets.includes(rawSet))
  
  // Interface para Exercício
  interface ExerciseRow {
    id: number
    grupo_muscular: string
    nome: string
    series: number
    repeticoes: number
    peso: number
    tempo: number
  }
  
  // Estado da tabela
  const rows = ref<ExerciseRow[]>([])
  const pagination = ref({ rowsPerPage: 0 })
  
  // Colunas para a tabela de exercícios
  import type { QTableColumn } from 'quasar'
  const columns: QTableColumn<ExerciseRow>[] = [
    { name: 'grupo_muscular', label: 'Grupo Muscular', field: 'grupo_muscular', align: 'left' },
    { name: 'nome', label: 'Exercício', field: 'nome', align: 'left' },
    { name: 'series', label: 'Séries', field: 'series', align: 'left' },
    { name: 'repeticoes', label: 'Repetições', field: 'repeticoes', align: 'left' },
    { name: 'peso', label: 'Peso (kg)', field: 'peso', align: 'left' },
    { name: 'tempo', label: 'Tempo (s)', field: 'tempo', align: 'left' },
    { name: 'actions', label: 'Ações', field: 'id', sortable: false }
  ]
  
  // Formulário
  const showDialog = ref(false)
  const isEditing = ref(false)
  const editId = ref<number | null>(null)
  const form = ref({ grupo_muscular: '', nome: '', series: 0, repeticoes: 0, peso: 0, tempo: 0 })
  
  
  // Funções de manipulação do formulário
  function resetForm() {
    form.value = { grupo_muscular: '', nome: '', series: 0, repeticoes: 0, peso: 0, tempo: 0 }
    isEditing.value = false
    editId.value = null
  }
  
  function openAddDialog() {
    resetForm()
    showDialog.value = true
  }
  
  function startEdit(row: ExerciseRow) {
    form.value = { 
      grupo_muscular: row.grupo_muscular,
      nome: row.nome, 
      series: row.series, 
      repeticoes: row.repeticoes, 
      peso: row.peso,
      tempo: row.tempo
    }
    editId.value = row.id
    isEditing.value = true
    showDialog.value = true
  }
  
  // Submeter o formulário para adicionar ou editar exercício
  async function submitForm() {
    const payload = {
      grupo_muscular: form.value.grupo_muscular,
      nome: form.value.nome,
      series: form.value.series,
      repeticoes: form.value.repeticoes,
      peso: form.value.peso,
      tempo: form.value.tempo
    }
  
    try {
      if (isEditing.value && editId.value !== null) {
        await api.put(`/WorkoutSet/${rawSet}/${editId.value}`, payload)
      } else {
        await api.post(`/WorkoutSet/${rawSet}`, payload)
      }
      await fetchExercises()
      showDialog.value = false
      resetForm()
    } catch (e: unknown) {
      const err = e as AxiosError
      console.error('Erro no submit:', err.response?.data || err.message)
    }
  }
  
  // Deletar exercício
  async function deleteExercise(id: number) {
    try {
      await api.delete(`/WorkoutSet/${rawSet}/${id}`)
      await fetchExercises()
    } catch (e: unknown) {
      console.error('Erro ao deletar exercício:', (e as AxiosError).message)
    }
  }
  
  // Buscar os exercícios para o conjunto
  async function fetchExercises() {
    if (!isValidSet.value) return
    try {
      const { data } = await api.get(`/WorkoutSet/${rawSet}`)
      rows.value = data.map((item: ExerciseRow) => ({
        id: item.id,
        grupo_muscular: item.grupo_muscular,
        nome: item.nome,
        series: item.series,
        repeticoes: item.repeticoes,
        peso: item.peso,
        tempo: item.tempo
      }))
    } catch (e: unknown) {
      const err = e as AxiosError
      console.error('Erro ao buscar exercícios:', err)
    }
  }
  
  // Carrega os dados quando o componente é montado
  onMounted(fetchExercises)
  
  // Observa mudanças no conjunto
  watch(() => route.params.wSet, fetchExercises)
  </script>
  