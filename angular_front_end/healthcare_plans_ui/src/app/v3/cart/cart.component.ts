import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-v3-cart',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="cart-page">
      <div class="page-header">
        <h1>My Cart</h1>
        <p>Review your selected plans and proceed to checkout</p>
      </div>
      <div class="cart-container">
        <div class="cart-items">
          <div class="empty-cart" *ngIf="cartItems.length === 0">
            <div class="empty-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <circle cx="9" cy="21" r="1"></circle>
                <circle cx="20" cy="21" r="1"></circle>
                <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
              </svg>
            </div>
            <h3>Your cart is empty</h3>
            <p>Browse our healthcare plans and add one to your cart</p>
            <a routerLink="/v3/plans" class="browse-btn">Browse Plans</a>
          </div>
          <div class="cart-item" *ngFor="let item of cartItems">
            <div class="item-info"><h4>{{ item.name }}</h4><p>{{ item.description }}</p></div>
            <div class="item-price"><span class="price">{{ item.price | currency }}/month</span><button class="remove-btn" (click)="removeItem(item)">Remove</button></div>
          </div>
        </div>
        <div class="cart-summary" *ngIf="cartItems.length > 0">
          <h3>Order Summary</h3>
          <div class="summary-row"><span>Subtotal</span><span>{{ subtotal | currency }}/month</span></div>
          <div class="summary-row"><span>Tax</span><span>{{ tax | currency }}/month</span></div>
          <div class="summary-row total"><span>Total</span><span>{{ total | currency }}/month</span></div>
          <button class="checkout-btn">Proceed to Checkout</button>
          <a routerLink="/v3/plans" class="continue-shopping">Continue Shopping</a>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .cart-page { animation: fadeIn 0.3s ease; }
    @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
    .page-header { margin-bottom: 2rem; }
    .page-header h1 { font-size: 2rem; color: #1e3a5f; margin: 0 0 0.5rem 0; }
    .page-header p { color: #666; margin: 0; font-size: 1.1rem; }
    .cart-container { display: grid; grid-template-columns: 1fr 350px; gap: 2rem; align-items: start; }
    .cart-items { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
    .empty-cart { text-align: center; padding: 3rem 1rem; }
    .empty-icon { width: 80px; height: 80px; margin: 0 auto 1.5rem; background: #f5f7fa; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
    .empty-icon svg { width: 40px; height: 40px; color: #999; }
    .empty-cart h3 { color: #1e3a5f; margin: 0 0 0.5rem 0; }
    .empty-cart p { color: #666; margin: 0 0 1.5rem 0; }
    .browse-btn { display: inline-block; padding: 0.75rem 2rem; background: #1976d2; color: white; text-decoration: none; border-radius: 8px; font-weight: 500; transition: background 0.2s ease; }
    .browse-btn:hover { background: #1565c0; }
    .cart-item { display: flex; justify-content: space-between; align-items: center; padding: 1rem 0; border-bottom: 1px solid #eee; }
    .cart-item:last-child { border-bottom: none; }
    .item-info h4 { margin: 0 0 0.25rem 0; color: #1e3a5f; }
    .item-info p { margin: 0; color: #666; font-size: 0.9rem; }
    .item-price { text-align: right; }
    .item-price .price { display: block; font-weight: 600; color: #1e3a5f; margin-bottom: 0.5rem; }
    .remove-btn { background: none; border: none; color: #e74c3c; cursor: pointer; font-size: 0.875rem; }
    .remove-btn:hover { text-decoration: underline; }
    .cart-summary { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 2px 8px rgba(0,0,0,0.08); position: sticky; top: 80px; }
    .cart-summary h3 { margin: 0 0 1rem 0; color: #1e3a5f; font-size: 1.25rem; }
    .summary-row { display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid #eee; color: #666; }
    .summary-row.total { border-bottom: none; border-top: 2px solid #1e3a5f; margin-top: 0.5rem; padding-top: 1rem; font-weight: 600; color: #1e3a5f; font-size: 1.1rem; }
    .checkout-btn { width: 100%; padding: 1rem; background: #1976d2; color: white; border: none; border-radius: 8px; font-size: 1rem; font-weight: 600; cursor: pointer; margin-top: 1.5rem; transition: background 0.2s ease; }
    .checkout-btn:hover { background: #1565c0; }
    .continue-shopping { display: block; text-align: center; margin-top: 1rem; color: #1976d2; text-decoration: none; }
    .continue-shopping:hover { text-decoration: underline; }
    @media (max-width: 900px) { .cart-container { grid-template-columns: 1fr; } .cart-summary { position: static; } }
    @media (max-width: 768px) { .page-header h1 { font-size: 1.5rem; } }
  `]
})
export class CartComponent {
  cartItems: any[] = [];
  get subtotal(): number { return this.cartItems.reduce((sum, item) => sum + item.price, 0); }
  get tax(): number { return this.subtotal * 0.08; }
  get total(): number { return this.subtotal + this.tax; }
  removeItem(item: any) { const index = this.cartItems.indexOf(item); if (index > -1) { this.cartItems.splice(index, 1); } }
}
