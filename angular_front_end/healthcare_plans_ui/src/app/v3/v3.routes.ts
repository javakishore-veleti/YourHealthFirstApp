import { Routes } from '@angular/router';
import { V3AuthGuard } from './guards/v3-auth.guard';
import { V3LayoutComponent } from './v3-layout/v3-layout.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { PlansComponent } from './plans/plans.component';
import { CartComponent } from './cart/cart.component';
import { AccountComponent } from './account/account.component';

export const V3_ROUTES: Routes = [
  {
    path: '',
    component: V3LayoutComponent,
    canActivate: [V3AuthGuard],
    children: [
      { path: '', component: DashboardComponent, title: 'Dashboard - HealthFirst' },
      { path: 'plans', component: PlansComponent, title: 'Healthcare Plans - HealthFirst' },
      { path: 'cart', component: CartComponent, title: 'My Cart - HealthFirst' },
      { path: 'account', component: AccountComponent, title: 'My Account - HealthFirst' }
    ]
  }
];
