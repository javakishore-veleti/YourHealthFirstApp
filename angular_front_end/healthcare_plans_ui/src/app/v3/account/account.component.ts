import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../v2/core/services/auth.service';

interface UserProfile { first_name: string; last_name: string; email: string; mobile_number: string; }

@Component({
  selector: 'app-v3-account',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="account-page">
      <div class="page-header"><h1>My Account</h1><p>Manage your profile and account settings</p></div>
      <div class="account-container">
        <div class="profile-card">
          <div class="profile-header">
            <div class="avatar"><span>{{ initials }}</span></div>
            <div class="profile-info"><h2>{{ user.first_name }} {{ user.last_name }}</h2><p>{{ user.email }}</p></div>
          </div>
        </div>
        <div class="settings-grid">
          <div class="settings-card">
            <div class="card-header">
              <h3>Personal Information</h3>
              <button class="edit-btn" *ngIf="!editingProfile" (click)="editingProfile = true">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                Edit
              </button>
            </div>
            <div class="card-body">
              <div class="info-grid" *ngIf="!editingProfile">
                <div class="info-item"><label>First Name</label><span>{{ user.first_name }}</span></div>
                <div class="info-item"><label>Last Name</label><span>{{ user.last_name }}</span></div>
                <div class="info-item"><label>Email</label><span>{{ user.email }}</span></div>
                <div class="info-item"><label>Phone</label><span>{{ user.mobile_number || 'Not set' }}</span></div>
              </div>
              <form *ngIf="editingProfile" (ngSubmit)="saveProfile()" class="edit-form">
                <div class="form-row">
                  <div class="form-group"><label>First Name</label><input type="text" [(ngModel)]="editUser.first_name" name="firstName" required></div>
                  <div class="form-group"><label>Last Name</label><input type="text" [(ngModel)]="editUser.last_name" name="lastName" required></div>
                </div>
                <div class="form-group"><label>Email</label><input type="email" [(ngModel)]="editUser.email" name="email" required></div>
                <div class="form-group"><label>Phone</label><input type="tel" [(ngModel)]="editUser.mobile_number" name="phone"></div>
                <div class="form-actions">
                  <button type="button" class="cancel-btn" (click)="cancelEdit()">Cancel</button>
                  <button type="submit" class="save-btn">Save Changes</button>
                </div>
              </form>
            </div>
          </div>
          <div class="settings-card">
            <div class="card-header"><h3>Security</h3></div>
            <div class="card-body">
              <div class="setting-item"><div class="setting-info"><h4>Password</h4><p>Last changed 30 days ago</p></div><button class="action-btn">Change Password</button></div>
              <div class="setting-item"><div class="setting-info"><h4>Two-Factor Authentication</h4><p>Add an extra layer of security</p></div><button class="action-btn">Enable</button></div>
            </div>
          </div>
          <div class="settings-card">
            <div class="card-header"><h3>Notifications</h3></div>
            <div class="card-body">
              <div class="toggle-item"><div class="toggle-info"><h4>Email Notifications</h4><p>Receive updates about your plans</p></div><label class="toggle"><input type="checkbox" [(ngModel)]="emailNotifications"><span class="slider"></span></label></div>
              <div class="toggle-item"><div class="toggle-info"><h4>SMS Notifications</h4><p>Get text alerts for important updates</p></div><label class="toggle"><input type="checkbox" [(ngModel)]="smsNotifications"><span class="slider"></span></label></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .account-page { animation: fadeIn 0.3s ease; }
    @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
    .page-header { margin-bottom: 2rem; }
    .page-header h1 { font-size: 2rem; color: #1e3a5f; margin: 0 0 0.5rem 0; }
    .page-header p { color: #666; margin: 0; font-size: 1.1rem; }
    .profile-card { background: linear-gradient(135deg, #1e3a5f 0%, #2d5a87 100%); border-radius: 12px; padding: 2rem; margin-bottom: 2rem; color: white; }
    .profile-header { display: flex; align-items: center; gap: 1.5rem; }
    .avatar { width: 80px; height: 80px; background: rgba(255,255,255,0.2); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 1.75rem; font-weight: 600; }
    .profile-info h2 { margin: 0 0 0.25rem 0; font-size: 1.5rem; }
    .profile-info p { margin: 0; opacity: 0.8; }
    .settings-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 1.5rem; }
    .settings-card { background: white; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); overflow: hidden; }
    .card-header { display: flex; justify-content: space-between; align-items: center; padding: 1rem 1.5rem; border-bottom: 1px solid #eee; }
    .card-header h3 { margin: 0; color: #1e3a5f; font-size: 1.1rem; }
    .edit-btn { display: flex; align-items: center; gap: 0.5rem; background: none; border: none; color: #1976d2; cursor: pointer; font-size: 0.9rem; }
    .edit-btn svg { width: 16px; height: 16px; }
    .card-body { padding: 1.5rem; }
    .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
    .info-item label { display: block; font-size: 0.875rem; color: #666; margin-bottom: 0.25rem; }
    .info-item span { color: #1e3a5f; font-weight: 500; }
    .edit-form { display: flex; flex-direction: column; gap: 1rem; }
    .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
    .form-group { display: flex; flex-direction: column; gap: 0.5rem; }
    .form-group label { font-size: 0.875rem; color: #666; }
    .form-group input { padding: 0.75rem; border: 1px solid #ddd; border-radius: 8px; font-size: 1rem; transition: border-color 0.2s ease; }
    .form-group input:focus { outline: none; border-color: #1976d2; }
    .form-actions { display: flex; justify-content: flex-end; gap: 1rem; margin-top: 0.5rem; }
    .cancel-btn { padding: 0.75rem 1.5rem; background: none; border: 1px solid #ddd; border-radius: 8px; cursor: pointer; color: #666; }
    .save-btn { padding: 0.75rem 1.5rem; background: #1976d2; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 500; }
    .save-btn:hover { background: #1565c0; }
    .setting-item, .toggle-item { display: flex; justify-content: space-between; align-items: center; padding: 1rem 0; border-bottom: 1px solid #eee; }
    .setting-item:last-child, .toggle-item:last-child { border-bottom: none; }
    .setting-info h4, .toggle-info h4 { margin: 0 0 0.25rem 0; color: #1e3a5f; font-size: 0.95rem; }
    .setting-info p, .toggle-info p { margin: 0; color: #666; font-size: 0.875rem; }
    .action-btn { padding: 0.5rem 1rem; background: none; border: 1px solid #1976d2; color: #1976d2; border-radius: 6px; cursor: pointer; font-size: 0.875rem; transition: all 0.2s ease; }
    .action-btn:hover { background: #1976d2; color: white; }
    .toggle { position: relative; display: inline-block; width: 50px; height: 28px; }
    .toggle input { opacity: 0; width: 0; height: 0; }
    .slider { position: absolute; cursor: pointer; top: 0; left: 0; right: 0; bottom: 0; background-color: #ccc; transition: 0.3s; border-radius: 28px; }
    .slider:before { position: absolute; content: ""; height: 20px; width: 20px; left: 4px; bottom: 4px; background-color: white; transition: 0.3s; border-radius: 50%; }
    input:checked + .slider { background-color: #1976d2; }
    input:checked + .slider:before { transform: translateX(22px); }
    @media (max-width: 768px) { .page-header h1 { font-size: 1.5rem; } .profile-header { flex-direction: column; text-align: center; } .info-grid, .form-row { grid-template-columns: 1fr; } .settings-grid { grid-template-columns: 1fr; } }
  `]
})
export class AccountComponent implements OnInit {
  private authService = inject(AuthService);
  user: UserProfile = { first_name: '', last_name: '', email: '', mobile_number: '' };
  editUser: UserProfile = { ...this.user };
  editingProfile = false;
  emailNotifications = true;
  smsNotifications = false;

  get initials(): string { return (this.user.first_name.charAt(0) + this.user.last_name.charAt(0)).toUpperCase(); }

  ngOnInit() {
    const currentUser = this.authService.getCurrentCustomer();
    if (currentUser) {
      this.user = { first_name: currentUser.first_name, last_name: currentUser.last_name, email: currentUser.email, mobile_number: currentUser.mobile_number || '' };
      this.editUser = { ...this.user };
    }
  }

  saveProfile() { this.user = { ...this.editUser }; this.editingProfile = false; }
  cancelEdit() { this.editUser = { ...this.user }; this.editingProfile = false; }
}
