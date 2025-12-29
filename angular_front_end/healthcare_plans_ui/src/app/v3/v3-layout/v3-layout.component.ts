import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { NavbarComponent } from '../navbar/navbar.component';

@Component({
  selector: 'app-v3-layout',
  standalone: true,
  imports: [CommonModule, RouterModule, NavbarComponent],
  template: `
    <div class="v3-layout">
      <app-v3-navbar></app-v3-navbar>
      <main class="v3-content">
        <router-outlet></router-outlet>
      </main>
      <footer class="v3-footer">
        <div class="footer-content">
          <p>&copy; 2024 HealthFirst. All rights reserved.</p>
        </div>
      </footer>
    </div>
  `,
  styles: [`
    .v3-layout { min-height: 100vh; display: flex; flex-direction: column; background: #f5f7fa; }
    .v3-content { flex: 1; padding: 2rem; max-width: 1200px; margin: 0 auto; width: 100%; box-sizing: border-box; }
    .v3-footer { background: #1e3a5f; color: white; padding: 1.5rem; margin-top: auto; }
    .footer-content { max-width: 1200px; margin: 0 auto; text-align: center; }
    .footer-content p { margin: 0; font-size: 0.875rem; opacity: 0.8; }
    @media (max-width: 768px) { .v3-content { padding: 1rem; } }
  `]
})
export class V3LayoutComponent {}
