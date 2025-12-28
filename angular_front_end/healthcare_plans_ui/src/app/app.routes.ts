import { Routes } from '@angular/router';

// src/app/app.routes.ts
export const routes: Routes = [
  // ... existing routes ...
  
  // ADD THIS:
  {
    path: 'v2',
    loadChildren: () => import('./v2/v2.module').then(m => m.V2Module)
  }
];