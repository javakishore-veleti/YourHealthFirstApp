# Angular V2 Module - Customer Profile

## Installation

### Step 1: Copy the `v2` folder
Copy the entire `v2` folder to:
```
angular_front_end/healthcare_plans_ui/src/app/v2/
```

### Step 2: Copy environment files
Copy the environment files to:
```
angular_front_end/healthcare_plans_ui/src/environments/
```

If `environments` folder doesn't exist, create it.

### Step 3: Update `app.routes.ts`
Add the V2 route to your existing routes file:

```typescript
// src/app/app.routes.ts

import { Routes } from '@angular/router';

export const routes: Routes = [
  // ... your existing routes ...
  
  // ADD THIS LINE:
  {
    path: 'v2',
    loadChildren: () => import('./v2/v2.module').then(m => m.V2Module)
  }
];
```

### Step 4: Update `app.config.ts` (if using standalone)
Make sure `provideHttpClient()` and `provideRouter(routes)` are configured:

```typescript
// src/app/app.config.ts
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient()
  ]
};
```

## File Structure

```
src/app/v2/
├── v2.module.ts                          # Main V2 module
├── core/
│   ├── models/
│   │   └── customer.model.ts             # Customer interfaces
│   ├── services/
│   │   └── auth.service.ts               # Authentication service
│   ├── guards/
│   │   └── auth.guard.ts                 # Route guard
│   └── interceptors/
│       └── auth.interceptor.ts           # JWT interceptor
└── customer-profile/
    ├── dto/
    │   ├── signup.dto.ts                 # Signup DTOs
    │   └── login.dto.ts                  # Login DTOs
    ├── services/
    │   └── customer.service.ts           # Customer API service
    └── components/
        ├── signup/
        │   ├── signup.component.ts
        │   ├── signup.component.html
        │   └── signup.component.css
        ├── login/
        │   ├── login.component.ts
        │   ├── login.component.html
        │   └── login.component.css
        └── profile/
            ├── profile.component.ts
            ├── profile.component.html
            └── profile.component.css

src/environments/
├── environment.ts                        # Development config
└── environment.prod.ts                   # Production config
```

## Routes

| Route | Component | Auth Required |
|-------|-----------|---------------|
| `/v2/signup` | SignupComponent | No |
| `/v2/login` | LoginComponent | No |
| `/v2/profile` | ProfileComponent | Yes |

## Testing Locally

1. Start Flask V2 backend (port 8081):
   ```bash
   cd python_flask_back_office/healthcare_plans_bo
   python v2/run_v2.py
   ```

2. Start Angular (port 4200):
   ```bash
   cd angular_front_end/healthcare_plans_ui
   ng serve
   ```

3. Open browser:
   - Signup: http://localhost:4200/v2/signup
   - Login: http://localhost:4200/v2/login
   - Profile: http://localhost:4200/v2/profile (requires login)

## API Endpoints (Flask V2)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v2/customers/signup` | Register new customer |
| POST | `/api/v2/customers/login` | Login and get JWT tokens |
| POST | `/api/v2/customers/refresh` | Refresh access token |
| GET | `/api/v2/customers/me` | Get current user profile |
