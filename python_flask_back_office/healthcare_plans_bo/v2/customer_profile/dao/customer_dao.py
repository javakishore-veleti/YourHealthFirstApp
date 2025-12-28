"""
Customer DAO Interface
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/dao/customer_dao.py
"""

from abc import ABC, abstractmethod
from typing import Optional, List
from v2.customer_profile.model import Customer


class CustomerDAO(ABC):
    """Abstract interface for Customer data access operations"""
    
    @abstractmethod
    def create(self, customer: Customer) -> Customer:
        """Create a new customer"""
        pass
    
    @abstractmethod
    def find_by_id(self, customer_id: int) -> Optional[Customer]:
        """Find customer by ID"""
        pass
    
    @abstractmethod
    def find_by_email(self, email: str) -> Optional[Customer]:
        """Find customer by email"""
        pass
    
    @abstractmethod
    def find_by_mobile(self, mobile_number: str) -> Optional[Customer]:
        """Find customer by mobile number"""
        pass
    
    @abstractmethod
    def update(self, customer: Customer) -> Customer:
        """Update existing customer"""
        pass
    
    @abstractmethod
    def delete(self, customer_id: int) -> bool:
        """Delete customer by ID"""
        pass
    
    @abstractmethod
    def find_all(self, page: int = 1, per_page: int = 10) -> List[Customer]:
        """Find all customers with pagination"""
        pass
    
    @abstractmethod
    def exists_by_email(self, email: str) -> bool:
        """Check if customer exists by email"""
        pass
    
    @abstractmethod
    def exists_by_mobile(self, mobile_number: str) -> bool:
        """Check if customer exists by mobile number"""
        pass
