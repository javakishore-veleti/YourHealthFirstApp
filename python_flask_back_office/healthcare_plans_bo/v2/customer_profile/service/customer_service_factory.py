"""
Customer Service Factory
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/service/customer_service_factory.py
"""

from v2.customer_profile.service.customer_service import CustomerService
from v2.customer_profile.service.impl.customer_service_impl import CustomerServiceImpl


class CustomerServiceFactory:
    """Factory for creating CustomerService instances"""
    
    _instance: CustomerService = None
    
    @classmethod
    def get_instance(cls) -> CustomerService:
        """Get singleton instance of CustomerService"""
        if cls._instance is None:
            cls._instance = CustomerServiceImpl()
        return cls._instance
    
    @classmethod
    def reset_instance(cls) -> None:
        """Reset singleton instance (useful for testing)"""
        cls._instance = None
