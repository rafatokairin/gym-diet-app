<template>
  <div>
    <q-page>
      <div class="q-pa-md">
        <q-btn push 
          class="full-width q-pa-lg" 
          color="teal"
          @click="showDialog = true"
        >
          {{ userGCD ? 'Atualizar' : 'Calcular' }} gasto calórico diário
        </q-btn>
        
        <!-- botão de remover se existir GCD -->
        <q-btn
          v-if="userGCD"
          push
          class="full-width q-pa-lg q-mt-md"
          color="red"
          @click="confirmDelete"
        >
          Remover GCD
        </q-btn>
      </div>

      <div class="row items-center justify-evenly q-gutter-lg q-pa-md">
        <q-btn
          v-for="day in days"
          :key="day"
          color="green"
          push
          @click="goToDay(day)"
          style="width: 150px"
        >
          <div class="row items-center no-wrap">
            <div class="text-center q-ma-lg">
              {{ day }}
            </div>
          </div>
        </q-btn>
      </div>

      <div class="q-pa-md" v-if="userGCD">
        <!-- carboidratos (4 kcal/g) -->
        <p>
          <span class="text-weight-medium">Carboidratos:</span>
          {{ userGCD.carboidratos_gcd }} g ({{ userGCD.carboidratos_gcd * 4 }} kcal/dia)
        </p>

        <!-- proteína (4 kcal/g) -->
        <p>
          <span class="text-weight-medium">Proteínas:</span>
          {{ userGCD.proteinas_gcd }} g ({{ userGCD.proteinas_gcd * 4 }} kcal/dia)
        </p>

        <!-- fibras -->
        <p>
          <span class="text-weight-medium">Fibras:</span>
          {{ userGCD.fibras_gcd }} g
        </p>

        <!-- gorduras (9 kcal/g) -->
        <p>
          <span class="text-weight-medium">Gorduras:</span>
          {{ userGCD.gorduras_gcd }} g ({{ userGCD.gorduras_gcd * 9 }} kcal/dia)
        </p>

        <!-- gasto calórico diário -->
        <p>
          <span class="text-weight-medium">Gasto calórico diário:</span>
          {{ userGCD.gcd }} kcal/dia
        </p>
      </div>

      <!-- dialog com form -->
      <q-dialog v-model="showDialog">
        <q-card class="q-pa-md" style="min-width: 300px">
          <q-card-section>
            <div class="text-h6">{{ userGCD ? 'Atualizar' : 'Calcular' }} gasto calórico diário</div>
          </q-card-section>

          <q-card-section>
            <q-input
              v-model.number="peso"
              label="Peso (kg)"
              type="number"
              filled
              class="q-mb-md"
            />
            <q-input
              v-model.number="altura"
              label="Altura (cm)"
              type="number"
              filled
              class="q-mb-md"
            />
            <q-input
              v-model.number="idade"
              label="Idade (anos)"
              type="number"
              filled
              class="q-mb-md"
            />
            <q-select
              v-model="fatorAtividade"
              :options="fatoresAF"
              label="Fator de atividade física"
              filled
              class="q-mb-md"
              emit-value
              map-options
            />
            <q-select
              v-model="fatorObjetivo"
              :options="fatoresO"
              label="Objetivo"
              filled
              class="q-mb-md"
              emit-value
              map-options
            />
          </q-card-section>

          <q-card-actions align="right">
            <q-btn flat label="Cancelar" v-close-popup />
            <q-btn
              :label="userGCD ? 'Atualizar' : 'Salvar'"
              color="primary"
              :disable="!peso || !altura || !idade || !fatorAtividade || !fatorObjetivo"
              @click="userGCD ? updateGasto() : addGasto()"
            />
          </q-card-actions>
        </q-card>
      </q-dialog>
      
      <!-- diálogo de confirmação para deletar -->
      <q-dialog v-model="showDeleteDialog">
        <q-card>
          <q-card-section>
            <div class="text-h6">Confirmar exclusão</div>
          </q-card-section>

          <q-card-section>
            Tem certeza que deseja remover seu gasto calórico diário?
          </q-card-section>

          <q-card-actions align="right">
            <q-btn flat label="Cancelar" v-close-popup />
            <q-btn flat label="Confirmar" color="negative" @click="deleteGasto" />
          </q-card-actions>
        </q-card>
      </q-dialog>
    </q-page>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useQuasar } from 'quasar'
import { api } from 'src/boot/axios'

interface UserGCD {
  carboidratos_gcd: number
  proteinas_gcd: number
  fibras_gcd: number
  gorduras_gcd: number
  gcd: number
}

const $q = useQuasar()
const router = useRouter()

const days = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo']

const showDialog = ref(false)
const showDeleteDialog = ref(false)
const userGCD = ref<UserGCD | null>(null)

const peso = ref<number | null>(null)
const altura = ref<number | null>(null)
const idade = ref<number | null>(null)
const fatorAtividade = ref<number | null>(null)
const fatorObjetivo = ref<number | null>(null)

const fatoresAF = [
  { label: 'Sedentário', value: 1.2 },
  { label: 'Pouca', value: 1.375 },
  { label: 'Moderada', value: 1.55 },
  { label: 'Intensa', value: 1.725 },
  { label: 'Muito intensa', value: 1.9 }
]

const fatoresO = [
  { label: 'Cutting', value: 0.6 },
  { label: 'Manutenção', value: 1 },
  { label: 'Bulking', value: 1.5 }
]

// carrega o GCD do usuário ao montar o componente
onMounted(() => {
  void loadUserGCD()
})

async function loadUserGCD() {
  try {
    const response = await api.get<UserGCD>('/UserGcd')
    userGCD.value = response.data
  } catch (error) {
    console.error('Erro ao carregar GCD:', error)
  }
}

function calculateGCD() {
  if (
    !peso.value ||
    !altura.value ||
    !idade.value ||
    !fatorAtividade.value ||
    !fatorObjetivo.value
  ) return null

  const bmr = 66.47 + (13.75 * peso.value) + (5 * altura.value) - (6.8 * idade.value)
  const gcd = Math.round(bmr * fatorAtividade.value)
  const proteinas_gcd = Math.round(fatorAtividade.value * peso.value)
  const gorduras_gcd = Math.round(fatorObjetivo.value * peso.value)
  const carboidratos_gcd = Math.round((gcd - (proteinas_gcd * 4) - (gorduras_gcd * 9)) / 4)
  const fibras_gcd = Math.round((gcd / 1000) * 14)

  return {
    carboidratos_gcd,
    proteinas_gcd,
    fibras_gcd,
    gorduras_gcd,
    gcd
  }
}

async function addGasto() {
  const gcdData = calculateGCD()
  if (!gcdData) return

  try {
    await api.post('/UserGcd', gcdData)
    $q.notify({
      type: 'positive',
      message: 'GCD cadastrado com sucesso!'
    })
    await loadUserGCD()
    resetForm()
    showDialog.value = false
  } catch (error) {
    $q.notify({
      type: 'negative',
      message: 'Erro ao cadastrar GCD'
    })
    console.error('Erro ao adicionar GCD:', error)
  }
}

async function updateGasto() {
  const gcdData = calculateGCD()
  if (!gcdData) return

  try {
    await api.put('/UserGcd', gcdData)
    $q.notify({
      type: 'positive',
      message: 'GCD atualizado com sucesso!'
    })
    await loadUserGCD()
    resetForm()
    showDialog.value = false
  } catch (error) {
    $q.notify({
      type: 'negative',
      message: 'Erro ao atualizar GCD'
    })
    console.error('Erro ao atualizar GCD:', error)
  }
}

function confirmDelete() {
  showDeleteDialog.value = true
}

async function deleteGasto() {
  try {
    await api.delete('/UserGcd')
    $q.notify({
      type: 'positive',
      message: 'GCD removido com sucesso!'
    })
    userGCD.value = null
    showDeleteDialog.value = false
  } catch (error) {
    $q.notify({
      type: 'negative',
      message: 'Erro ao remover GCD'
    })
    console.error('Erro ao remover GCD:', error)
  }
}

function resetForm() {
  peso.value = null
  altura.value = null
  idade.value = null
  fatorAtividade.value = null
  fatorObjetivo.value = null
}

function goToDay(day: string) {
  void router.push({ name: 'dDay', params: { dDay: day } })
}
</script>
