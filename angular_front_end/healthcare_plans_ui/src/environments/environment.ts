/**
 * Environment Configuration - Development
 * Location: src/environments/environment.ts
 */

export const environment = {
  production: false,
  
  // V2 API URL - Flask Backend
  // For local development: http://localhost:8081/api/v2
  // For Cloud Run: https://healthcare-plans-bo-v2-dev-xxx.a.run.app/api/v2
  apiUrl: 'http://localhost:8081/api/v2',
  
  // App Settings
  appName: 'YourHealthPlans',
  version: '2.0.0'
};
