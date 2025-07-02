// src/boot/axios.ts
import { boot } from 'quasar/wrappers'
import axios, { type AxiosInstance } from 'axios'

declare module 'vue' {
  interface ComponentCustomProperties {
    $axios: AxiosInstance
    $api: AxiosInstance
  }
}

// aponta para seu backend local
const api = axios.create({
  baseURL: 'http://localhost:8080', // ajuste para o seu backend
  withCredentials: true
})

export default boot(({ app }) => {
  app.config.globalProperties.$axios = axios
  app.config.globalProperties.$api = api
})

export { api }