<template>
  <div>
    <q-page>
      <div class="q-pa-md">
        <!-- botão para montar agenda -->
        <q-btn
          push
          class="full-width q-pa-lg"
          color="pink"
          @click="openDialog"
        >
          Montar agenda
        </q-btn>
      </div>

      <!-- botões dos treinos existentes -->
      <div class="row items-center justify-evenly q-gutter-lg q-pa-md">
        <q-btn
          v-for="set in allSets"
          :key="set"
          color="red"
          push
          @click="goToSet(set)"
          style="width: 150px"
        >
          <div class="row items-center no-wrap">
            <div class="text-center q-ma-lg">
              Treino {{ set }}
            </div>
          </div>
        </q-btn>
      </div>

      <!-- dialog com formulário para montar agenda -->
      <q-dialog v-model="showDialog">
        <q-card class="q-pa-md" style="min-width: 300px">
          <q-card-section>
            <div class="text-h6">Montar agenda</div>
          </q-card-section>

          <q-card-section>
            <q-select
              v-model="selectedSet"
              :options="availableSets"
              label="Escolha o treino"
              filled
            />

            <div class="q-mt-md">
              <div class="text-subtitle2">Dias da semana</div>
              <div class="row q-gutter-sm q-mt-sm">
                <q-checkbox
                  v-for="day in daysOfWeek"
                  :key="day"
                  :label="day"
                  v-model="selectedDays"
                  :val="day"
                  :disable="isDayTaken(day)"
                />
              </div>
            </div>
          </q-card-section>

          <q-card-actions align="right">
            <q-btn flat label="Cancelar" v-close-popup />
            <q-btn
              label="Salvar"
              color="primary"
              :disable="!selectedSet"
              @click="addSet"
            />
          </q-card-actions>
        </q-card>
      </q-dialog>
    </q-page>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { api } from 'boot/axios'

const router = useRouter()

const allSets = ['A', 'B', 'C', 'D', 'E']
const daysOfWeek = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo']

// mapping entre os formatos de exibição e banco de dados
const dayMapping: Record<string, string> = {
  'Segunda': 'segunda',
  'Terça': 'terca',
  'Quarta': 'quarta',
  'Quinta': 'quinta',
  'Sexta': 'sexta',
  'Sábado': 'sabado',
  'Domingo': 'domingo'
}

const reverseDayMapping: Record<string, string> = {
  'segunda': 'Segunda',
  'terca': 'Terça',
  'quarta': 'Quarta',
  'quinta': 'Quinta',
  'sexta': 'Sexta',
  'sabado': 'Sábado',
  'domingo': 'Domingo'
}

const showDialog = ref(false)
const selectedSet = ref<string | null>(null)
const selectedDays = ref<string[]>([])

const createdSets = ref<{ name: string, days: string[] }[]>([])

onMounted(async () => {
  await fetchUserWorkouts()
})

async function fetchUserWorkouts() {
  try {
    const response = await api.get('/workouts')
    const workouts = response.data as { setName: string, days: string[] }[]

    createdSets.value = workouts.map(workout => ({
      name: workout.setName,
      days: workout.days.map(dbDay => reverseDayMapping[dbDay] || dbDay)
    }))
  } catch (err) {
    console.error('Erro ao carregar treinos:', err)
  }
}

const availableSets = computed(() => allSets)

function isDayTaken(day: string): boolean {
  return createdSets.value.some(set => 
    set.name !== selectedSet.value && set.days.includes(day)
  )
}

watch(selectedSet, (newSet) => {
  if (newSet) {
    const existingSet = createdSets.value.find(set => set.name === newSet)
    selectedDays.value = existingSet ? [...existingSet.days] : []
  } else {
    selectedDays.value = []
  }
})

async function addSet() {
  const setName = selectedSet.value
  const days = selectedDays.value.map(day => dayMapping[day] || day.toLowerCase())

  if (!setName) return

  try {
    await api.post('/workouts/set-days', {
      setName,
      days
    })

    const existingSet = createdSets.value.find(set => set.name === setName)

    if (existingSet) {
      existingSet.days = selectedDays.value
    } else {
      createdSets.value.push({ name: setName, days: [...selectedDays.value] })
    }

    selectedSet.value = null
    selectedDays.value = []
    showDialog.value = false

  } catch (err) {
    console.error('Erro ao montar agenda:', err)
  }
}

function goToSet(set: string) {
  void router.push({ name: 'wSet', params: { wSet: set } })
}

function openDialog() {
  selectedSet.value = null
  selectedDays.value = []
  showDialog.value = true
}
</script>
