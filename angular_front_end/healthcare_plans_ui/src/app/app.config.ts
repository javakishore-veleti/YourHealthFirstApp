import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors, HttpRequest, HttpHandlerFn } from '@angular/common/http';
import { routes } from './app.routes';

// Simple functional interceptor
function authInterceptor(req: HttpRequest<unknown>, next: HttpHandlerFn) {
  console.log('=== INTERCEPTOR ===', req.url);
  const token = localStorage.getItem('yhp_access_token');
  
  if (token) {
    console.log('Adding token to request');
    req = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
  }
  
  return next(req);
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor]))
  ]
};