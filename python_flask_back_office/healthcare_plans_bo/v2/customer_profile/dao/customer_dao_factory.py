"""
Customer DAO Factory
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/dao/customer_dao_factory.py
"""

from v2.customer_profile.dao.customer_dao import CustomerDAO
from v2.customer_profile.dao.impl.customer_dao_impl import CustomerDAOImpl


class CustomerDAOFactory:
    """Factory for creating CustomerDAO instances"""
    
    _instance: CustomerDAO = None
    
    @classmethod
    def get_instance(cls) -> CustomerDAO:
        """Get singleton instance of CustomerDAO"""
        if cls._instance is None:
            cls._instance = CustomerDAOImpl()
        return cls._instance
    
    @classmethod
    def reset_instance(cls) -> None:
        """Reset singleton instance (useful for testing)"""
        cls._instance = None
