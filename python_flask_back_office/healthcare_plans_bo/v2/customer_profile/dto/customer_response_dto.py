"""
Customer Response DTO
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/dto/customer_response_dto.py
"""

from dataclasses import dataclass
from typing import Optional
from datetime import datetime, date


@dataclass
class CustomerResponseDTO:
    """DTO for customer profile response"""
    id: int
    email: str
    mobile_number: str
    first_name: str
    last_name: str
    full_name: str
    date_of_birth: Optional[date]
    address: Optional[str]
    city: Optional[str]
    state: Optional[str]
    pincode: Optional[str]
    is_active: bool
    is_verified: bool
    created_at: datetime
    
    @classmethod
    def from_model(cls, customer) -> 'CustomerResponseDTO':
        """Create DTO from Customer model"""
        return cls(
            id=customer.id,
            email=customer.email,
            mobile_number=customer.mobile_number,
            first_name=customer.first_name,
            last_name=customer.last_name,
            full_name=customer.full_name,
            date_of_birth=customer.date_of_birth,
            address=customer.address,
            city=customer.city,
            state=customer.state,
            pincode=customer.pincode,
            is_active=customer.is_active,
            is_verified=customer.is_verified,
            created_at=customer.created_at
        )
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON response"""
        return {
            'id': self.id,
            'email': self.email,
            'mobile_number': self.mobile_number,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'full_name': self.full_name,
            'date_of_birth': self.date_of_birth.isoformat() if self.date_of_birth else None,
            'address': self.address,
            'city': self.city,
            'state': self.state,
            'pincode': self.pincode,
            'is_active': self.is_active,
            'is_verified': self.is_verified,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
