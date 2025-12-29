import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../v2/core/services/auth.service';

@Component({
  selector: 'app-v3-navbar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <nav class="navbar">
      <div class="navbar-container">
        <a routerLink="/v3" class="navbar-brand">
          <svg class="heart-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
          </svg>
          <span class="brand-text">HealthFirst</span>
        </a>
        <div class="navbar-menu">
          <a routerLink="/v3/plans" routerLinkActive="active" class="nav-link">Plans</a>
          <a routerLink="/v3/cart" routerLinkActive="active" class="nav-link">My Cart</a>
          <span class="nav-divider">|</span>
          <a routerLink="/v3/account" routerLinkActive="active" class="nav-link">My Account</a>
          <button class="user-icon-btn" (click)="toggleUserMenu()">
            <svg class="user-icon" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
            </svg>
          </button>
        </div>
        <button class="mobile-menu-btn" (click)="toggleMobileMenu()">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="3" y1="6" x2="21" y2="6"></line>
            <line x1="3" y1="12" x2="21" y2="12"></line>
            <line x1="3" y1="18" x2="21" y2="18"></line>
          </svg>
        </button>
      </div>
      <div class="user-dropdown" [class.show]="showUserMenu">
        <div class="dropdown-header">
          <span class="user-name">{{ userName }}</span>
          <span class="user-email">{{ userEmail }}</span>
        </div>
        <div class="dropdown-divider"></div>
        <a routerLink="/v3/account" class="dropdown-item" (click)="showUserMenu = false">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
            <circle cx="12" cy="7" r="4"></circle>
          </svg>
          My Profile
        </a>
        <button class="dropdown-item logout" (click)="logout()">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
            <polyline points="16 17 21 12 16 7"></polyline>
            <line x1="21" y1="12" x2="9" y2="12"></line>
          </svg>
          Logout
        </button>
      </div>
      <div class="mobile-menu" [class.show]="showMobileMenu">
        <a routerLink="/v3/plans" routerLinkActive="active" class="mobile-nav-link" (click)="showMobileMenu = false">Plans</a>
        <a routerLink="/v3/cart" routerLinkActive="active" class="mobile-nav-link" (click)="showMobileMenu = false">My Cart</a>
        <a routerLink="/v3/account" routerLinkActive="active" class="mobile-nav-link" (click)="showMobileMenu = false">My Account</a>
        <div class="mobile-divider"></div>
        <button class="mobile-nav-link logout" (click)="logout()">Logout</button>
      </div>
    </nav>
    <div class="overlay" [class.show]="showUserMenu || showMobileMenu" (click)="closeMenus()"></div>
  `,
  styles: [`
    .navbar { background: linear-gradient(135deg, #1e3a5f 0%, #2d5a87 100%); box-shadow: 0 2px 10px rgba(0,0,0,0.1); position: sticky; top: 0; z-index: 1000; }
    .navbar-container { max-width: 1200px; margin: 0 auto; padding: 0 1rem; height: 64px; display: flex; align-items: center; justify-content: space-between; }
    .navbar-brand { display: flex; align-items: center; gap: 0.5rem; text-decoration: none; color: white; }
    .heart-icon { width: 32px; height: 32px; color: #e74c3c; fill: #e74c3c; }
    .brand-text { font-size: 1.5rem; font-weight: 700; color: white; }
    .navbar-menu { display: flex; align-items: center; gap: 1.5rem; }
    .nav-link { color: white; text-decoration: none; font-size: 1rem; font-weight: 500; padding: 0.5rem 0; border-bottom: 2px solid transparent; transition: all 0.2s ease; }
    .nav-link:hover { color: #a8d4ff; }
    .nav-link.active { border-bottom-color: white; }
    .nav-divider { color: rgba(255,255,255,0.4); font-weight: 300; }
    .user-icon-btn { background: rgba(255,255,255,0.1); border: none; border-radius: 50%; width: 40px; height: 40px; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: background 0.2s ease; }
    .user-icon-btn:hover { background: rgba(255,255,255,0.2); }
    .user-icon { width: 24px; height: 24px; color: white; }
    .mobile-menu-btn { display: none; background: none; border: none; color: white; cursor: pointer; padding: 0.5rem; }
    .mobile-menu-btn svg { width: 24px; height: 24px; }
    .user-dropdown { position: absolute; top: 64px; right: 1rem; background: white; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.15); min-width: 220px; opacity: 0; visibility: hidden; transform: translateY(-10px); transition: all 0.2s ease; z-index: 1001; }
    .user-dropdown.show { opacity: 1; visibility: visible; transform: translateY(0); }
    .dropdown-header { padding: 1rem; display: flex; flex-direction: column; gap: 0.25rem; }
    .user-name { font-weight: 600; color: #1e3a5f; }
    .user-email { font-size: 0.875rem; color: #666; }
    .dropdown-divider { height: 1px; background: #eee; }
    .dropdown-item { display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem 1rem; color: #333; text-decoration: none; width: 100%; border: none; background: none; font-size: 0.95rem; cursor: pointer; transition: background 0.2s ease; }
    .dropdown-item:hover { background: #f5f5f5; }
    .dropdown-item svg { width: 18px; height: 18px; color: #666; }
    .dropdown-item.logout { color: #e74c3c; }
    .dropdown-item.logout svg { color: #e74c3c; }
    .mobile-menu { display: none; position: absolute; top: 64px; left: 0; right: 0; background: #1e3a5f; padding: 1rem; opacity: 0; visibility: hidden; transform: translateY(-10px); transition: all 0.2s ease; }
    .mobile-menu.show { opacity: 1; visibility: visible; transform: translateY(0); }
    .mobile-nav-link { display: block; color: white; text-decoration: none; padding: 0.75rem 1rem; border-radius: 4px; transition: background 0.2s ease; width: 100%; text-align: left; background: none; border: none; font-size: 1rem; cursor: pointer; }
    .mobile-nav-link:hover { background: rgba(255,255,255,0.1); }
    .mobile-nav-link.active { background: rgba(255,255,255,0.15); }
    .mobile-nav-link.logout { color: #ff6b6b; }
    .mobile-divider { height: 1px; background: rgba(255,255,255,0.2); margin: 0.5rem 0; }
    .overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.3); opacity: 0; visibility: hidden; transition: all 0.2s ease; z-index: 999; }
    .overlay.show { opacity: 1; visibility: visible; }
    @media (max-width: 768px) {
      .navbar-menu { display: none; }
      .mobile-menu-btn { display: block; }
      .mobile-menu { display: block; }
      .user-dropdown { right: 1rem; left: 1rem; min-width: auto; }
    }
  `]
})
export class NavbarComponent implements OnInit {
  private authService = inject(AuthService);
  private router = inject(Router);
  showUserMenu = false;
  showMobileMenu = false;
  userName = '';
  userEmail = '';

  ngOnInit() {
    const user = this.authService.getCurrentCustomer();
    if (user) {
      this.userName = `${user.first_name} ${user.last_name}`;
      this.userEmail = user.email;
    }
  }

  toggleUserMenu() { this.showUserMenu = !this.showUserMenu; this.showMobileMenu = false; }
  toggleMobileMenu() { this.showMobileMenu = !this.showMobileMenu; this.showUserMenu = false; }
  closeMenus() { this.showUserMenu = false; this.showMobileMenu = false; }
  logout() { this.authService.logout(); }
}
