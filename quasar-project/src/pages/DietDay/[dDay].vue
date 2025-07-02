<template>
  <div>
    <ErrorNotFound v-if="!isValidDay" />
    <q-page v-else class="q-pa-md">
      <div class="q-pa-md">
        <q-btn
          push
          class="full-width q-pa-lg"
          color="teal"
          label="Adicionar alimento"
          @click="openAddDialog"
        />
      </div>

      <!-- Diálogo para adicionar/editar alimento -->
      <q-dialog v-model="showDialog">
        <q-card class="q-pa-md" style="min-width: 400px">
          <q-card-section>
            <div class="text-h6">
              {{ isEditing ? 'Editar alimento' : 'Novo alimento' }}
            </div>
          </q-card-section>

          <q-card-section>
            <q-input v-model="form.name" label="Nome do alimento" />
            <q-input v-model.number="form.weight" type="number" label="Peso (g)" />
            <q-input v-model.number="form.carbs" type="number" label="Carboidratos (g)" />
            <q-input v-model.number="form.protein" type="number" label="Proteínas (g)" />
            <q-input v-model.number="form.fiber" type="number" label="Fibras (g)" />
            <q-input v-model.number="form.fat" type="number" label="Gorduras (g)" />
          </q-card-section>

          <q-card-actions align="right">
            <q-btn flat label="Cancelar" v-close-popup @click="resetForm" />
            <q-btn
              :label="isEditing ? 'Salvar' : 'Adicionar'"
              color="primary"
              @click="submitForm"
              :disable="!form.name"
            />
          </q-card-actions>
        </q-card>
      </q-dialog>

      <div class="q-pa-md">
        <q-table
          flat bordered
          :title="`Dieta de ${displayDay}`"
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
              <q-td key="name" :props="props">{{ props.row.name }}</q-td>
              <q-td key="weight" :props="props"><q-badge color="green">{{ props.row.weight }}</q-badge></q-td>
              <q-td key="carbs" :props="props"><q-badge color="purple">{{ props.row.carbs }}</q-badge></q-td>
              <q-td key="protein" :props="props"><q-badge color="orange">{{ props.row.protein }}</q-badge></q-td>
              <q-td key="fiber" :props="props"><q-badge color="primary">{{ props.row.fiber }}</q-badge></q-td>
              <q-td key="fat" :props="props"><q-badge color="teal">{{ props.row.fat }}</q-badge></q-td>
              <q-td key="kcal" :props="props"><q-badge color="accent">{{ props.row.kcal }}</q-badge></q-td>
              <q-td key="actions" :props="props">
                <q-btn dense flat icon="edit" color="primary" @click="startEdit(props.row)" />
                <q-btn dense flat icon="delete" color="negative" @click="deleteFood(props.row.id)" />
              </q-td>
            </q-tr>
          </template>
        </q-table>

        <!-- Seção de totais e metas -->
        <div class="q-pa-md">
          <div class="row wrap q-gutter-md items-center">
            <div class="text-weight-medium q-pr-md">Total / Meta</div>

            <div class="q-pr-md">
              <span>Carboidratos:</span>
              <q-badge color="purple" class="q-ml-xs">
                {{ totals.carbs }} g / {{ userGCD?.carboidratos_gcd || 0 }} g
              </q-badge>
            </div>

            <div class="q-pr-md">
              <span>Proteínas:</span>
              <q-badge color="orange" class="q-ml-xs">
                {{ totals.protein }} g / {{ userGCD?.proteinas_gcd || 0 }} g
              </q-badge>
            </div>

            <div class="q-pr-md">
              <span>Fibras:</span>
              <q-badge color="primary" class="q-ml-xs">
                {{ totals.fiber }} g / {{ userGCD?.fibras_gcd || 0 }} g
              </q-badge>
            </div>

            <div class="q-pr-md">
              <span>Gorduras:</span>
              <q-badge color="teal" class="q-ml-xs">
                {{ totals.fat }} g / {{ userGCD?.gorduras_gcd || 0 }} g
              </q-badge>
            </div>

            <div class="q-pr-md">
              <span>Calorias:</span>
              <q-badge color="accent" class="q-ml-xs">
                {{ totals.kcal }} kcal / {{ userGCD?.gcd || 0 }} kcal
              </q-badge>
            </div>
          </div>
        </div>
      </div>
    </q-page>
  </div>
</template>

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import { ref, computed, onMounted, watch } from 'vue'
import { api } from 'boot/axios'
import type { AxiosError } from 'axios'
import ErrorNotFound from 'pages/ErrorNotFound.vue'

// Interface para UserGCD
interface UserGCD {
  carboidratos_gcd: number
  proteinas_gcd: number
  fibras_gcd: number
  gorduras_gcd: number
  gcd: number
}

// parâmetros da rota
const route = useRoute()
const router = useRouter()
const rawDay = route.params.dDay as string
const normalizedDay = computed(() => rawDay.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLowerCase())
const displayDay = computed(() => rawDay)

// dias válidos
const days = ['segunda','terca','quarta','quinta','sexta','sabado','domingo']
const isValidDay = computed(() => days.includes(normalizedDay.value))

// interface com id
interface FoodRow {
  id: number
  name: string
  weight: number
  carbs: number
  protein: number
  fiber: number
  fat: number
  kcal: number
}

// estado da tabela
const rows = ref<FoodRow[]>([])
const userGCD = ref<UserGCD | null>(null)
const pagination = ref({ rowsPerPage: 0 })

// colunas (simplificadas)
import type { QTableColumn } from 'quasar'
const columns: QTableColumn<FoodRow>[] = [
  { name: 'name', label: 'Alimento', field: 'name', align: 'left' },
  { name: 'weight', label: 'Peso (g)', field: 'weight', align: 'left' },
  { name: 'carbs', label: 'Carboidratos (g)', field: 'carbs', align: 'left' },
  { name: 'protein', label: 'Proteínas (g)', field: 'protein', align: 'left' },
  { name: 'fiber', label: 'Fibras (g)', field: 'fiber', align: 'left' },
  { name: 'fat', label: 'Gorduras (g)', field: 'fat', align: 'left' },
  { name: 'kcal', label: 'Calorias (kcal)', field: 'kcal', align: 'left' },
  { name: 'actions', label: 'Ações', field: 'id', sortable: false }
]

// formulário
const showDialog = ref(false)
const isEditing = ref(false)
const editId = ref<number | null>(null)
const form = ref({ name: '', weight: 0, carbs: 0, protein: 0, fiber: 0, fat: 0 })

// Totais calculados
const totals = computed(() => {
  return rows.value.reduce((acc, food) => ({
    carbs: acc.carbs + food.carbs,
    protein: acc.protein + food.protein,
    fiber: acc.fiber + food.fiber,
    fat: acc.fat + food.fat,
    kcal: acc.kcal + food.kcal
  }), { carbs: 0, protein: 0, fiber: 0, fat: 0, kcal: 0 })
})

function resetForm() {
  form.value = { name: '', weight: 0, carbs: 0, protein: 0, fiber: 0, fat: 0 }
  isEditing.value = false
  editId.value = null
}

function openAddDialog() {
  resetForm()
  showDialog.value = true
}

function startEdit(row: FoodRow) {
  form.value = { name: row.name, weight: row.weight, carbs: row.carbs, protein: row.protein, fiber: row.fiber, fat: row.fat }
  editId.value = row.id
  isEditing.value = true
  showDialog.value = true
}

async function submitForm() {
  const payload = {
    alimento: form.value.name,
    peso: form.value.weight,
    carboidratos: form.value.carbs,
    proteinas: form.value.protein,
    fibras: form.value.fiber,
    gorduras: form.value.fat,
    calorias: form.value.protein * 4 + form.value.carbs * 4 + form.value.fat * 9
  }
  try {
    if (isEditing.value && editId.value !== null) {
      await api.put(`/DietDay/${normalizedDay.value}/${editId.value}`, payload)
    } else {
      await api.post(`/DietDay/${normalizedDay.value}`, payload)
    }
    await fetchFoods()
    showDialog.value = false
  } catch (e: unknown) {
    const err = e as AxiosError
    console.error('Erro no submit:', err.response?.data || err.message)
  }
}

async function deleteFood(id: number) {
  try {
    await api.delete(`/DietDay/${normalizedDay.value}/${id}`)
    await fetchFoods()
  } catch (e: unknown) {
    console.error('Erro ao deletar:', (e as AxiosError).message)
  }
}

// tipo bruto da API
interface RawFood {
  id: number
  alimento: string
  peso: number
  carboidratos: number
  proteinas: number
  fibras: number
  gorduras: number
  calorias: number
}

// fetch dos alimentos
async function fetchFoods() {
  if (!isValidDay.value) return
  try {
    const { data } = await api.get<RawFood[]>(`/DietDay/${normalizedDay.value}`)
    rows.value = data.map(item => ({
      id: item.id,
      name: item.alimento,
      weight: item.peso,
      carbs: item.carboidratos,
      protein: item.proteinas,
      fiber: item.fibras,
      fat: item.gorduras,
      kcal: item.calorias
    }))
  } catch (e: unknown) {
    const err = e as AxiosError
    if (err.response?.status === 401) {
      await router.replace('/login')
    } else {
      console.error('Erro ao buscar dieta:', err)
    }
  }
}

// fetch do UserGCD
async function fetchUserGCD() {
  try {
    const { data } = await api.get<UserGCD>('/UserGcd')
    userGCD.value = data
  } catch (e: unknown) {
    const err = e as AxiosError
    if (err.response?.status !== 404) { // Ignora se não encontrado
      console.error('Erro ao buscar GCD:', err.response?.data || err.message)
    }
  }
}

// Carrega os dados quando o componente é montado
onMounted(async () => {
  await fetchFoods()
  await fetchUserGCD()
})

// Observa mudanças no dia
watch(() => route.params.dDay, async () => {
  await fetchFoods()
})
</script>