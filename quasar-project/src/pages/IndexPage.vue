<template>
  <div>
    <q-inner-loading :showing="loading" />
    <q-page v-if="!loading">
      <div class="text-h6 text-center q-pt-md">Hoje é {{ today }}</div>
      <div class="q-pa-md">
        <q-carousel
          v-model="slide"
          transition-prev="jump-right"
          transition-next="jump-left"
          animated
          height="640px"
          control-color="primary"
          style="background: transparent;"
        >
          <q-carousel-slide name="workout" class="q-pa-none">
            <q-table
              flat
              bordered
              :title="workoutDayName ? `Treino ${workoutDayName}` : `Sem treino`"
              :rows="workoutData"
              :columns="columnsWorkout"
              row-key="id"
              v-model:pagination="pagination"
              :rows-per-page-options="[0]"
              style="width: 100%; height: 100%;"
              :virtual-scroll="true" 
            >
              <template v-slot:body="props">
                <q-tr :props="props">
                  <q-td key="group">{{ props.row.grupo_muscular }}</q-td>
                  <q-td key="name">{{ props.row.nome }}</q-td>
                  <q-td key="weight"><q-badge color="green">{{ props.row.peso }}</q-badge></q-td>
                  <q-td key="set"><q-badge color="purple">{{ props.row.series }}</q-badge></q-td>
                  <q-td key="reps"><q-badge color="orange">{{ props.row.repeticoes }}</q-badge></q-td>
                  <q-td key="time"><q-badge color="primary">{{ props.row.tempo }}</q-badge></q-td>
                </q-tr>
              </template>
            </q-table>
          </q-carousel-slide>

          <q-carousel-slide name="food" class="q-pa-none">
            <q-table
              flat
              bordered
              :title="`Dieta de ${today}`"
              :rows="dietData"
              :columns="columnsFood"
              row-key="id"
              v-model:pagination="pagination"
              :rows-per-page-options="[0]"
              style="width: 100%; height: 100%;"
              :virtual-scroll="true"
            >
              <template v-slot:body="props">
                <q-tr :props="props">
                  <q-td key="name">{{ props.row.alimento }}</q-td>
                  <q-td key="weight"><q-badge color="green">{{ props.row.peso }}</q-badge></q-td>
                  <q-td key="carbs"><q-badge color="purple">{{ props.row.carboidratos }}</q-badge></q-td>
                  <q-td key="protein"><q-badge color="orange">{{ props.row.proteinas }}</q-badge></q-td>
                  <q-td key="fiber"><q-badge color="primary">{{ props.row.fibras }}</q-badge></q-td>
                  <q-td key="fat"><q-badge color="teal">{{ props.row.gorduras }}</q-badge></q-td>
                  <q-td key="kcal"><q-badge color="accent">{{ props.row.calorias }}</q-badge></q-td>
                </q-tr>
              </template>
            </q-table>
          </q-carousel-slide>
        </q-carousel>
        <div class="row justify-center q-pa-md">
          <q-btn-toggle
            push
            v-model="slide"
            :options="[
              { label: '1', value: 'workout' },
              { label: '2', value: 'food' },
            ]"
          />
        </div>
      </div>
    </q-page>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from 'boot/axios'
import type { QTableColumn } from 'quasar'

const displayDays = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado']
const apiDays = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado']
const todayIndex = new Date().getDay() // 0-6 (domingo-sábado)
const today = displayDays[todayIndex]
const apiDay = apiDays[todayIndex]

interface WorkoutItem {
  id: number
  workout: {
    id: number
    workoutCategory: {
      id: number
      nome: string
    }
  }
  grupo_muscular: string
  nome: string
  peso: number
  series: number
  repeticoes: number
  tempo: number
}

interface DietItem {
  id: number
  alimento: string
  peso: number
  carboidratos: number
  proteinas: number
  fibras: number
  gorduras: number
  calorias: number
}

const workoutData = ref<WorkoutItem[]>([])
const dietData = ref<DietItem[]>([])
const workoutDayName = ref('')
const loading = ref(true)

const columnsWorkout: QTableColumn<WorkoutItem>[] = [
  { name: 'group', label: 'Grupo muscular', align: 'left', field: 'grupo_muscular', sortable: true },
  { name: 'name', label: 'Exercício', align: 'left', field: 'nome', sortable: true },
  { name: 'weight', label: 'Peso (kg)', field: 'peso', align: 'left', sortable: true },
  { name: 'set', label: 'Séries', field: 'series', align: 'left', sortable: true },
  { name: 'reps', label: 'Repetições', field: 'repeticoes', align: 'left', sortable: true },
  { name: 'time', label: 'Tempo (min)', field: 'tempo', align: 'left', sortable: true },
]

const columnsFood: QTableColumn<DietItem>[] = [
  { name: 'name', label: 'Alimento', align: 'left', field: 'alimento', required: true, sortable: true },
  { name: 'weight', label: 'Peso (g)', field: 'peso', align: 'left', sortable: true },
  { name: 'carbs', label: 'Carboidratos (g)', field: 'carboidratos', align: 'left', sortable: true },
  { name: 'protein', label: 'Proteínas (g)', field: 'proteinas', align: 'left', sortable: true },
  { name: 'fiber', label: 'Fibras (g)', field: 'fibras', align: 'left', sortable: true },
  { name: 'fat', label: 'Gorduras (g)', field: 'gorduras', align: 'left', sortable: true },
  { name: 'kcal', label: 'Total calorias (kcal)', field: 'calorias', align: 'left', sortable: true},
]

const slide = ref('workout')
const pagination = ref({ rowsPerPage: 0 })

async function fetchTodayData() {
  loading.value = true
  try {
    // usa apiDay para as requisições
    const workoutResponse = await api.get<WorkoutItem[]>(`/workouts/${apiDay}`)
    workoutData.value = workoutResponse.data
    
    if (workoutData.value.length > 0 && workoutData.value[0]?.workout?.workoutCategory) {
      workoutDayName.value = workoutData.value[0].workout.workoutCategory.nome
    }
    
    const dietResponse = await api.get<DietItem[]>(`/DietDay/${apiDay}`)
    dietData.value = dietResponse.data
    
  } catch (error) {
    console.error('Error fetching today data:', error)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await fetchTodayData()
})
</script>
