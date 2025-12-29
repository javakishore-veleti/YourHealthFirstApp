import { Routes } from '@angular/router';

export const routes: Routes = [
  // Default redirect to V3
  {
    path: '',
    redirectTo: '/v3',
    pathMatch: 'full'
  },

  // V2 Routes - Your existing module (unchanged)
  {
    path: 'v2',
    loadChildren: () => import('./v2/v2.module').then(m => m.V2Module)
  },

  // V3 Routes - New standalone routes
  {
    path: 'v3',
    loadChildren: () => import('./v3/v3.routes').then(m => m.V3_ROUTES)
  },

  // Fallback
  {
    path: '**',
    redirectTo: '/v3'
  }
];