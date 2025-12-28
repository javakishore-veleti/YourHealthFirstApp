"""
Login DTOs (Request/Response)
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/dto/login_dto.py
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class LoginRequestDTO:
    """DTO for customer login request"""
    email: str
    password: str
    
    @classmethod
    def from_dict(cls, data: dict) -> 'LoginRequestDTO':
        """Create DTO from dictionary"""
        return cls(
            email=data.get('email', '').strip().lower(),
            password=data.get('password', '')
        )
    
    def validate(self) -> tuple[bool, Optional[str]]:
        """Validate login data"""
        if not self.email or '@' not in self.email:
            return False, 'Valid email is required'
        if not self.password:
            return False, 'Password is required'
        return True, None


@dataclass
class LoginResponseDTO:
    """DTO for customer login response"""
    success: bool
    message: str
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    customer_id: Optional[int] = None
    email: Optional[str] = None
    full_name: Optional[str] = None
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON response"""
        result = {
            'success': self.success,
            'message': self.message
        }
        if self.success:
            result['data'] = {
                'access_token': self.access_token,
                'refresh_token': self.refresh_token,
                'customer': {
                    'id': self.customer_id,
                    'email': self.email,
                    'full_name': self.full_name
                }
            }
        return result
