/**
 * V2 Routing Module
 * Location: src/app/v2/v2-routing.module.ts
 */

import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

const routes: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full'
  },
  // Customer Profile routes are loaded via CustomerProfileRoutingModule
  // Routes: /v2/signup, /v2/login, /v2/profile
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class V2RoutingModule { }
