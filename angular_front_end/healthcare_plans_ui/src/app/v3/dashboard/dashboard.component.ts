import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '../../v2/core/services/auth.service';

@Component({
  selector: 'app-v3-dashboard',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="dashboard">
      <div class="welcome-section">
        <h1>Welcome back, {{ firstName }}!</h1>
        <p>Manage your healthcare plans and account settings</p>
      </div>
      <div class="card-grid">
        <a routerLink="/v3/plans" class="dashboard-card plans-card">
          <div class="card-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
          </div>
          <h3>Healthcare Plans</h3>
          <p>Browse and compare available healthcare plans</p>
          <span class="card-action">View Plans →</span>
        </a>
        <a routerLink="/v3/cart" class="dashboard-card cart-card">
          <div class="card-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>
          </div>
          <h3>My Cart</h3>
          <p>Review items in your cart</p>
          <span class="card-action">View Cart →</span>
        </a>
        <a routerLink="/v3/account" class="dashboard-card account-card">
          <div class="card-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
          </div>
          <h3>My Account</h3>
          <p>Update your profile and settings</p>
          <span class="card-action">Manage Account →</span>
        </a>
      </div>
      <div class="activity-section">
        <h2>Quick Actions</h2>
        <div class="activity-list">
          <div class="activity-item">
            <div class="activity-icon blue"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg></div>
            <div class="activity-content"><h4>Find a Plan</h4><p>Search for healthcare plans that fit your needs</p></div>
          </div>
          <div class="activity-item">
            <div class="activity-icon green"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg></div>
            <div class="activity-content"><h4>Coverage Details</h4><p>View your current coverage information</p></div>
          </div>
          <div class="activity-item">
            <div class="activity-icon purple"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg></div>
            <div class="activity-content"><h4>Schedule Appointment</h4><p>Book a consultation with our advisors</p></div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .dashboard { animation: fadeIn 0.3s ease; }
    @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
    .welcome-section { margin-bottom: 2rem; }
    .welcome-section h1 { font-size: 2rem; color: #1e3a5f; margin: 0 0 0.5rem 0; }
    .welcome-section p { color: #666; margin: 0; font-size: 1.1rem; }
    .card-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
    .dashboard-card { background: white; border-radius: 12px; padding: 1.5rem; text-decoration: none; color: inherit; box-shadow: 0 2px 8px rgba(0,0,0,0.08); transition: all 0.2s ease; display: block; }
    .dashboard-card:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.12); }
    .card-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; margin-bottom: 1rem; }
    .card-icon svg { width: 24px; height: 24px; }
    .plans-card .card-icon { background: #e3f2fd; color: #1976d2; }
    .cart-card .card-icon { background: #e8f5e9; color: #388e3c; }
    .account-card .card-icon { background: #f3e5f5; color: #7b1fa2; }
    .dashboard-card h3 { font-size: 1.25rem; color: #1e3a5f; margin: 0 0 0.5rem 0; }
    .dashboard-card p { color: #666; margin: 0 0 1rem 0; font-size: 0.95rem; }
    .card-action { color: #1976d2; font-weight: 500; font-size: 0.9rem; }
    .activity-section { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
    .activity-section h2 { font-size: 1.25rem; color: #1e3a5f; margin: 0 0 1rem 0; }
    .activity-list { display: flex; flex-direction: column; gap: 1rem; }
    .activity-item { display: flex; align-items: center; gap: 1rem; padding: 1rem; background: #f8f9fa; border-radius: 8px; cursor: pointer; transition: background 0.2s ease; }
    .activity-item:hover { background: #f0f2f5; }
    .activity-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
    .activity-icon svg { width: 20px; height: 20px; }
    .activity-icon.blue { background: #e3f2fd; color: #1976d2; }
    .activity-icon.green { background: #e8f5e9; color: #388e3c; }
    .activity-icon.purple { background: #f3e5f5; color: #7b1fa2; }
    .activity-content h4 { margin: 0 0 0.25rem 0; color: #1e3a5f; font-size: 1rem; }
    .activity-content p { margin: 0; color: #666; font-size: 0.875rem; }
    @media (max-width: 768px) { .welcome-section h1 { font-size: 1.5rem; } .card-grid { grid-template-columns: 1fr; } }
  `]
})
export class DashboardComponent implements OnInit {
  private authService = inject(AuthService);
  firstName = '';

  ngOnInit() {
    const user = this.authService.getCurrentCustomer();
    if (user) { this.firstName = user.first_name; }
  }
}
