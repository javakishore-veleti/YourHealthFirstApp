import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';

// Services
import { AuthService } from './core/services/auth.service';
import { CustomerService } from './customer-profile/services/customer.service';

// Guards
import { AuthGuard } from './core/guards/auth.guard';

// Components
import { SignupComponent } from './customer-profile/components/signup/signup.component';
import { LoginComponent } from './customer-profile/components/login/login.component';
import { ProfileComponent } from './customer-profile/components/profile/profile.component';

const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: 'signup', component: SignupComponent },
  { path: 'login', component: LoginComponent },
  { path: 'profile', component: ProfileComponent, canActivate: [AuthGuard] }
];

@NgModule({
  declarations: [
    SignupComponent,
    LoginComponent,
    ProfileComponent
  ],
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule.forChild(routes)
  ],
  providers: [
    AuthService,
    CustomerService,
    AuthGuard
  ]
})
export class V2Module { }