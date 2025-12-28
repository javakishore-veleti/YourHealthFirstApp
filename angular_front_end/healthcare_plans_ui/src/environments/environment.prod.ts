/**
 * Environment Configuration - Production
 * Location: src/environments/environment.prod.ts
 */

export const environment = {
  production: true,
  
  // V2 API URL - Cloud Run Backend
  // Update this with your actual Cloud Run service URL
  apiUrl: 'https://healthcare-plans-bo-v2-dev-XXXXX-uc.a.run.app/api/v2',
  
  // App Settings
  appName: 'YourHealthPlans',
  version: '2.0.0'
};
