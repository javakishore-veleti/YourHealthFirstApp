import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, catchError, throwError } from 'rxjs';
import { Customer, ApiResponse } from '../../core/models/customer.model';
import { environment } from '../../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class CustomerService {
  private readonly API_URL = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getCustomerById(id: number): Observable<ApiResponse<Customer>> {
    return this.http.get<ApiResponse<Customer>>(`${this.API_URL}/customers/${id}`)
      .pipe(
        catchError(error => {
          console.error('Get customer error:', error);
          return throwError(() => error.error || { success: false, message: 'Failed to get customer' });
        })
      );
  }

  updateProfile(id: number, data: Partial<Customer>): Observable<ApiResponse<Customer>> {
    return this.http.put<ApiResponse<Customer>>(`${this.API_URL}/customers/${id}`, data)
      .pipe(
        catchError(error => {
          console.error('Update profile error:', error);
          return throwError(() => error.error || { success: false, message: 'Failed to update profile' });
        })
      );
  }

  changePassword(oldPassword: string, newPassword: string): Observable<ApiResponse<void>> {
    return this.http.post<ApiResponse<void>>(`${this.API_URL}/customers/change-password`, {
      old_password: oldPassword,
      new_password: newPassword
    }).pipe(
      catchError(error => {
        console.error('Change password error:', error);
        return throwError(() => error.error || { success: false, message: 'Failed to change password' });
      })
    );
  }
}
