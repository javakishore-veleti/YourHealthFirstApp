/**
 * V2 Module - Root module for V2 features
 * Location: src/app/v2/v2.module.ts
 */

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClientModule } from '@angular/common/http';

import { V2RoutingModule } from './v2-routing.module';
import { CoreModule } from './core/core.module';
import { CustomerProfileModule } from './customer-profile/customer-profile.module';

@NgModule({
  declarations: [],
  imports: [
    CommonModule,
    HttpClientModule,
    CoreModule,
    CustomerProfileModule,
    V2RoutingModule
  ]
})
export class V2Module { }
