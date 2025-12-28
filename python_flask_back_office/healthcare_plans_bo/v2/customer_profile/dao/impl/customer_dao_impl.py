"""
Customer DAO Implementation
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/dao/impl/customer_dao_impl.py
"""

from typing import Optional, List
from v2.extensions_v2 import db
from v2.customer_profile.model import Customer
from v2.customer_profile.dao.customer_dao import CustomerDAO


class CustomerDAOImpl(CustomerDAO):
    """SQLAlchemy implementation of Customer DAO"""
    
    def create(self, customer: Customer) -> Customer:
        """Create a new customer"""
        db.session.add(customer)
        db.session.commit()
        db.session.refresh(customer)
        return customer
    
    def find_by_id(self, customer_id: int) -> Optional[Customer]:
        """Find customer by ID"""
        return db.session.get(Customer, customer_id)
    
    def find_by_email(self, email: str) -> Optional[Customer]:
        """Find customer by email"""
        return Customer.query.filter_by(email=email.lower()).first()
    
    def find_by_mobile(self, mobile_number: str) -> Optional[Customer]:
        """Find customer by mobile number"""
        return Customer.query.filter_by(mobile_number=mobile_number).first()
    
    def update(self, customer: Customer) -> Customer:
        """Update existing customer"""
        db.session.commit()
        db.session.refresh(customer)
        return customer
    
    def delete(self, customer_id: int) -> bool:
        """Delete customer by ID"""
        customer = self.find_by_id(customer_id)
        if customer:
            db.session.delete(customer)
            db.session.commit()
            return True
        return False
    
    def find_all(self, page: int = 1, per_page: int = 10) -> List[Customer]:
        """Find all customers with pagination"""
        pagination = Customer.query.paginate(
            page=page, 
            per_page=per_page, 
            error_out=False
        )
        return pagination.items
    
    def exists_by_email(self, email: str) -> bool:
        """Check if customer exists by email"""
        return Customer.query.filter_by(email=email.lower()).first() is not None
    
    def exists_by_mobile(self, mobile_number: str) -> bool:
        """Check if customer exists by mobile number"""
        return Customer.query.filter_by(mobile_number=mobile_number).first() is not None
