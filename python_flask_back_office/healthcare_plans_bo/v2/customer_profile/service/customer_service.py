"""
Customer Service Interface
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/service/customer_service.py
"""

from abc import ABC, abstractmethod
from v2.customer_profile.dto import (
    SignupRequestDTO, SignupResponseDTO,
    LoginRequestDTO, LoginResponseDTO,
    CustomerResponseDTO
)


class CustomerService(ABC):
    """Abstract interface for Customer business operations"""
    
    @abstractmethod
    def signup(self, request: SignupRequestDTO) -> SignupResponseDTO:
        """Register a new customer"""
        pass
    
    @abstractmethod
    def login(self, request: LoginRequestDTO) -> LoginResponseDTO:
        """Authenticate customer and return tokens"""
        pass
    
    @abstractmethod
    def get_profile(self, customer_id: int) -> CustomerResponseDTO:
        """Get customer profile by ID"""
        pass
    
    @abstractmethod
    def update_profile(self, customer_id: int, data: dict) -> CustomerResponseDTO:
        """Update customer profile"""
        pass
    
    @abstractmethod
    def change_password(self, customer_id: int, old_password: str, new_password: str) -> bool:
        """Change customer password"""
        pass
    
    @abstractmethod
    def deactivate_account(self, customer_id: int) -> bool:
        """Deactivate customer account"""
        pass
