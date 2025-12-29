import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-v3-plans',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="plans-page">
      <div class="page-header">
        <h1>Healthcare Plans</h1>
        <p>Choose the plan that's right for you and your family</p>
      </div>
      <div class="plans-grid">
        <div class="plan-card">
          <div class="plan-header basic"><h3>Basic</h3><div class="price"><span class="amount">$99</span><span class="period">/month</span></div></div>
          <div class="plan-body">
            <ul class="features">
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Primary care visits</li>
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Preventive care</li>
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Generic prescriptions</li>
              <li class="disabled"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>Specialist visits</li>
              <li class="disabled"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>Hospital coverage</li>
            </ul>
            <button class="select-btn">Select Plan</button>
          </div>
        </div>
        <div class="plan-card popular">
          <div class="popular-badge">Most Popular</div>
          <div class="plan-header standard"><h3>Standard</h3><div class="price"><span class="amount">$199</span><span class="period">/month</span></div></div>
          <div class="plan-body">
            <ul class="features">
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Primary care visits</li>
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Preventive care</li>
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>All prescriptions</li>
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Specialist visits</li>
              <li class="disabled"><svg viewBox="0 0 24 24" fill="currentColor"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>Hospital coverage</li>
            </ul>
            <button class="select-btn primary">Select Plan</button>
          </div>
        </div>
        <div class="plan-card">
          <div class="plan-header premium"><h3>Premium</h3><div class="price"><span class="amount">$349</span><span class="period">/month</span></div></div>
          <div class="plan-body">
            <ul class="features">
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Unlimited primary care</li>
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Preventive care</li>
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>All prescriptions</li>
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Unlimited specialists</li>
              <li><svg viewBox="0 0 24 24" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>Full hospital coverage</li>
            </ul>
            <button class="select-btn">Select Plan</button>
          </div>
        </div>
      </div>
      <div class="info-banner">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>
        <p>Need help choosing? Our healthcare advisors are available 24/7 to assist you.</p>
      </div>
    </div>
  `,
  styles: [`
    .plans-page { animation: fadeIn 0.3s ease; }
    @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
    .page-header { text-align: center; margin-bottom: 2rem; }
    .page-header h1 { font-size: 2rem; color: #1e3a5f; margin: 0 0 0.5rem 0; }
    .page-header p { color: #666; margin: 0; font-size: 1.1rem; }
    .plans-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
    .plan-card { background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.08); position: relative; transition: transform 0.2s ease, box-shadow 0.2s ease; }
    .plan-card:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.12); }
    .plan-card.popular { border: 2px solid #1976d2; }
    .popular-badge { position: absolute; top: 0; right: 0; background: #1976d2; color: white; padding: 0.25rem 1rem; font-size: 0.75rem; font-weight: 600; border-radius: 0 10px 0 8px; }
    .plan-header { padding: 1.5rem; text-align: center; color: white; }
    .plan-header.basic { background: linear-gradient(135deg, #607d8b 0%, #455a64 100%); }
    .plan-header.standard { background: linear-gradient(135deg, #1976d2 0%, #1565c0 100%); }
    .plan-header.premium { background: linear-gradient(135deg, #7b1fa2 0%, #6a1b9a 100%); }
    .plan-header h3 { margin: 0 0 0.5rem 0; font-size: 1.25rem; font-weight: 600; }
    .price { display: flex; align-items: baseline; justify-content: center; gap: 0.25rem; }
    .price .amount { font-size: 2.5rem; font-weight: 700; }
    .price .period { font-size: 1rem; opacity: 0.8; }
    .plan-body { padding: 1.5rem; }
    .features { list-style: none; padding: 0; margin: 0 0 1.5rem 0; }
    .features li { display: flex; align-items: center; gap: 0.75rem; padding: 0.75rem 0; border-bottom: 1px solid #f0f0f0; color: #333; }
    .features li:last-child { border-bottom: none; }
    .features li svg { width: 20px; height: 20px; color: #4caf50; flex-shrink: 0; }
    .features li.disabled { color: #999; }
    .features li.disabled svg { color: #ccc; }
    .select-btn { width: 100%; padding: 0.875rem; border: 2px solid #1e3a5f; background: white; color: #1e3a5f; font-size: 1rem; font-weight: 600; border-radius: 8px; cursor: pointer; transition: all 0.2s ease; }
    .select-btn:hover { background: #1e3a5f; color: white; }
    .select-btn.primary { background: #1976d2; border-color: #1976d2; color: white; }
    .select-btn.primary:hover { background: #1565c0; border-color: #1565c0; }
    .info-banner { display: flex; align-items: center; gap: 1rem; background: #e3f2fd; padding: 1rem 1.5rem; border-radius: 8px; color: #1565c0; }
    .info-banner svg { width: 24px; height: 24px; flex-shrink: 0; }
    .info-banner p { margin: 0; }
    @media (max-width: 768px) { .page-header h1 { font-size: 1.5rem; } .plans-grid { grid-template-columns: 1fr; } }
  `]
})
export class PlansComponent {}
