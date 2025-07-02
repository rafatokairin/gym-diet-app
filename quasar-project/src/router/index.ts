import { defineRouter } from '#q-app/wrappers'
import {
  createMemoryHistory,
  createRouter,
  createWebHashHistory,
  createWebHistory
} from 'vue-router'
import routes from './routes'
import { api } from 'boot/axios'

export default defineRouter(function () {
  const createHistory = process.env.SERVER
    ? createMemoryHistory
    : (process.env.VUE_ROUTER_MODE === 'history' ? createWebHistory : createWebHashHistory)

  const Router = createRouter({
    scrollBehavior: () => ({ left: 0, top: 0 }),
    routes,
    history: createHistory(process.env.VUE_ROUTER_BASE),
  })

  Router.beforeEach(async (to, from, next) => {
    const publicPages = ['/login', '/register']
    const authRequired = !publicPages.includes(to.path)

    if (!authRequired) {
      return next()
    }

    try {
      // Tenta acessar uma rota protegida no backend
      await api.get('/auth/check') // essa rota precisa estar protegida por token
      next()
    } catch {
      console.error('Acesso negado. Redirecionando para login...')
      next('/login')
    }
  })

  return Router
})
