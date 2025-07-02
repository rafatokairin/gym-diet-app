import type { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    // encapsula tudo dentro desse layout (component)
    component: () => import('layouts/MainLayout.vue'),
    children: [
      { path: '', component: () => import('pages/IndexPage.vue') },
      { path: 'index', component: () => import('pages/IndexPage.vue') },
      { path: 'account', component: () => import('pages/AccountPage.vue') },
      { path: 'workouts', component: () => import('pages/WorkoutsPage.vue') },
      { path: 'diets', component: () => import('pages/DietsPage.vue') },
      { path: '/WorkoutSet/:wSet', name: 'wSet', component: () => import('pages/WorkoutSet/[wSet].vue') },
      { path: '/DietDay/:dDay', name: 'dDay', component: () => import('pages/DietDay/[dDay].vue') }
    ],
  },
  {
    path: '/login',
    component: () => import('pages/LoginPage.vue')
  },
  {
    path: '/register',
    component: () => import('pages/RegisterPage.vue')
  },

  // Always leave this as last one,
  // but you can also remove it
  {
    path: '/:catchAll(.*)*',
    component: () => import('pages/ErrorNotFound.vue'),
  },
];

export default routes;
