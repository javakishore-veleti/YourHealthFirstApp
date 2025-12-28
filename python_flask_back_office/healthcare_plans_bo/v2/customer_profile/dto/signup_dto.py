"""
Signup DTOs (Request/Response)
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/dto/signup_dto.py
"""

from dataclasses import dataclass
from typing import Optional


@dataclass
class SignupRequestDTO:
    """DTO for customer signup request"""
    email: str
    mobile_number: str
    password: str
    first_name: str
    last_name: str
    
    @classmethod
    def from_dict(cls, data: dict) -> 'SignupRequestDTO':
        """Create DTO from dictionary"""
        return cls(
            email=data.get('email', '').strip().lower(),
            mobile_number=data.get('mobile_number', '').strip(),
            password=data.get('password', ''),
            first_name=data.get('first_name', '').strip(),
            last_name=data.get('last_name', '').strip()
        )
    
    def validate(self) -> tuple[bool, Optional[str]]:
        """Validate signup data"""
        if not self.email or '@' not in self.email:
            return False, 'Valid email is required'
        if not self.mobile_number or len(self.mobile_number) < 10:
            return False, 'Valid mobile number is required (minimum 10 digits)'
        if not self.password or len(self.password) < 8:
            return False, 'Password must be at least 8 characters'
        if not self.first_name:
            return False, 'First name is required'
        if not self.last_name:
            return False, 'Last name is required'
        return True, None


@dataclass
class SignupResponseDTO:
    """DTO for customer signup response"""
    success: bool
    message: str
    customer_id: Optional[int] = None
    email: Optional[str] = None
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON response"""
        result = {
            'success': self.success,
            'message': self.message
        }
        if self.customer_id:
            result['customer_id'] = self.customer_id
        if self.email:
            result['email'] = self.email
        return result
