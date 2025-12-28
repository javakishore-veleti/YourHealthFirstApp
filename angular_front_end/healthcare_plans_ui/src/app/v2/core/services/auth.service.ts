import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, tap, catchError, throwError } from 'rxjs';
import { Router } from '@angular/router';
import { Customer, ApiResponse } from '../models/customer.model';
import { LoginRequestDTO, LoginResponseDTO } from '../../customer-profile/dto/login.dto';
import { SignupRequestDTO, SignupResponseDTO } from '../../customer-profile/dto/signup.dto';
import { environment } from '../../../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly API_URL = environment.apiUrl;
  private readonly ACCESS_TOKEN_KEY = 'yhp_access_token';
  private readonly REFRESH_TOKEN_KEY = 'yhp_refresh_token';
  private readonly CUSTOMER_KEY = 'yhp_customer';

  private isAuthenticatedSubject = new BehaviorSubject<boolean>(this.hasToken());
  private currentCustomerSubject = new BehaviorSubject<Customer | null>(this.getStoredCustomer());

  public isAuthenticated$ = this.isAuthenticatedSubject.asObservable();
  public currentCustomer$ = this.currentCustomerSubject.asObservable();

  constructor(
    private http: HttpClient,
    private router: Router
  ) {
    console.log('AuthService initialized, API_URL:', this.API_URL);
  }

  signup(request: SignupRequestDTO): Observable<SignupResponseDTO> {
    return this.http.post<SignupResponseDTO>(`${this.API_URL}/customers/signup`, request)
      .pipe(
        catchError(error => {
          console.error('Signup error:', error);
          return throwError(() => error.error || { success: false, message: 'Signup failed' });
        })
      );
  }

  login(request: LoginRequestDTO): Observable<LoginResponseDTO> {
    console.log('Login request:', request);
    return this.http.post<LoginResponseDTO>(`${this.API_URL}/customers/login`, request)
      .pipe(
        tap(response => {
          console.log('Login response received:', response);
          console.log('Response success:', response.success);
          console.log('Response data:', response.data);
          
          if (response.success && response.data) {
            console.log('Saving tokens to localStorage...');
            this.setTokens(response.data.access_token, response.data.refresh_token);
            this.setCustomer(response.data.customer);
            this.isAuthenticatedSubject.next(true);
            
            // Verify tokens were saved
            console.log('Token saved:', this.getAccessToken()?.substring(0, 20) + '...');
            console.log('Customer saved:', this.getCurrentCustomer());
          } else {
            console.log('Response success is false or no data');
          }
        }),
        catchError(error => {
          console.error('Login error:', error);
          return throwError(() => error.error || { success: false, message: 'Login failed' });
        })
      );
  }

  refreshToken(): Observable<{ success: boolean; access_token: string }> {
    const refreshToken = this.getRefreshToken();
    console.log('Refresh token exists:', !!refreshToken);
    
    return this.http.post<{ success: boolean; access_token: string }>(
      `${this.API_URL}/customers/refresh`,
      {},
      {
        headers: {
          'Authorization': `Bearer ${refreshToken}`
        }
      }
    ).pipe(
      tap(response => {
        if (response.success && response.access_token) {
          this.setAccessToken(response.access_token);
        }
      }),
      catchError(error => {
        console.error('Refresh token error:', error);
        this.logout();
        return throwError(() => error);
      })
    );
  }

  getProfile(): Observable<ApiResponse<Customer>> {
    const token = this.getAccessToken();
    console.log('GetProfile called, token exists:', !!token);
    
    return this.http.get<ApiResponse<Customer>>(`${this.API_URL}/customers/me`)
      .pipe(
        tap(response => {
          console.log('GetProfile response:', response);
          if (response.success && response.data) {
            this.currentCustomerSubject.next(response.data);
            localStorage.setItem(this.CUSTOMER_KEY, JSON.stringify(response.data));
          }
        }),
        catchError(error => {
          console.error('Get profile error:', error);
          return throwError(() => error.error || { success: false, message: 'Failed to get profile' });
        })
      );
  }

  logout(): void {
    console.log('Logout called');
    localStorage.removeItem(this.ACCESS_TOKEN_KEY);
    localStorage.removeItem(this.REFRESH_TOKEN_KEY);
    localStorage.removeItem(this.CUSTOMER_KEY);
    this.isAuthenticatedSubject.next(false);
    this.currentCustomerSubject.next(null);
    this.router.navigate(['/v2/login']);
  }

  getAccessToken(): string | null {
    return localStorage.getItem(this.ACCESS_TOKEN_KEY);
  }

  getRefreshToken(): string | null {
    return localStorage.getItem(this.REFRESH_TOKEN_KEY);
  }

  isAuthenticated(): boolean {
    return this.hasToken();
  }

  getCurrentCustomer(): Customer | null {
    return this.currentCustomerSubject.value;
  }

  private hasToken(): boolean {
    return !!localStorage.getItem(this.ACCESS_TOKEN_KEY);
  }

  private setTokens(accessToken: string, refreshToken: string): void {
    console.log('setTokens called');
    localStorage.setItem(this.ACCESS_TOKEN_KEY, accessToken);
    localStorage.setItem(this.REFRESH_TOKEN_KEY, refreshToken);
    console.log('Tokens set in localStorage');
  }

  private setAccessToken(accessToken: string): void {
    localStorage.setItem(this.ACCESS_TOKEN_KEY, accessToken);
  }

  private setCustomer(customer: any): void {
    console.log('setCustomer called:', customer);
    localStorage.setItem(this.CUSTOMER_KEY, JSON.stringify(customer));
    this.currentCustomerSubject.next(customer);
  }

  private getStoredCustomer(): Customer | null {
    const stored = localStorage.getItem(this.CUSTOMER_KEY);
    return stored ? JSON.parse(stored) : null;
  }
}