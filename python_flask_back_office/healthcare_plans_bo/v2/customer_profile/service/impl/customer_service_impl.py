"""
Customer Service Implementation
Location: python_flask_back_office/healthcare_plans_bo/v2/customer_profile/service/impl/customer_service_impl.py
"""

from flask_jwt_extended import create_access_token, create_refresh_token
from v2.customer_profile.service.customer_service import CustomerService
from v2.customer_profile.dao import CustomerDAO, CustomerDAOFactory
from v2.customer_profile.model import Customer
from v2.customer_profile.dto import (
    SignupRequestDTO, SignupResponseDTO,
    LoginRequestDTO, LoginResponseDTO,
    CustomerResponseDTO
)


class CustomerServiceImpl(CustomerService):
    """Implementation of Customer business operations"""
    
    def __init__(self, customer_dao: CustomerDAO = None):
        """Initialize with DAO dependency"""
        self._customer_dao = customer_dao or CustomerDAOFactory.get_instance()
    
    def signup(self, request: SignupRequestDTO) -> SignupResponseDTO:
        """Register a new customer"""
        
        # Validate request
        is_valid, error_message = request.validate()
        if not is_valid:
            return SignupResponseDTO(
                success=False,
                message=error_message
            )
        
        # Check if email already exists
        if self._customer_dao.exists_by_email(request.email):
            return SignupResponseDTO(
                success=False,
                message='Email already registered'
            )
        
        # Check if mobile already exists
        if self._customer_dao.exists_by_mobile(request.mobile_number):
            return SignupResponseDTO(
                success=False,
                message='Mobile number already registered'
            )
        
        # Create new customer
        customer = Customer(
            email=request.email,
            mobile_number=request.mobile_number,
            first_name=request.first_name,
            last_name=request.last_name
        )
        customer.set_password(request.password)
        
        # Save to database
        created_customer = self._customer_dao.create(customer)
        
        return SignupResponseDTO(
            success=True,
            message='Account created successfully',
            customer_id=created_customer.id,
            email=created_customer.email
        )
    
    def login(self, request: LoginRequestDTO) -> LoginResponseDTO:
        """Authenticate customer and return tokens"""
        
        # Validate request
        is_valid, error_message = request.validate()
        if not is_valid:
            return LoginResponseDTO(
                success=False,
                message=error_message
            )
        
        # Find customer by email
        customer = self._customer_dao.find_by_email(request.email)
        
        if not customer:
            return LoginResponseDTO(
                success=False,
                message='Invalid email or password'
            )
        
        # Verify password
        if not customer.check_password(request.password):
            return LoginResponseDTO(
                success=False,
                message='Invalid email or password'
            )
        
        # Check if account is active
        if not customer.is_active:
            return LoginResponseDTO(
                success=False,
                message='Account is deactivated. Please contact support.'
            )
        
        # Update last login
        customer.update_last_login()
        self._customer_dao.update(customer)
        
        # Generate JWT tokens
        access_token = create_access_token(identity=str(customer.id))
        refresh_token = create_refresh_token(identity=str(customer.id))
        
        return LoginResponseDTO(
            success=True,
            message='Login successful',
            access_token=access_token,
            refresh_token=refresh_token,
            customer_id=customer.id,
            email=customer.email,
            full_name=customer.full_name
        )
    
    def get_profile(self, customer_id: int) -> CustomerResponseDTO:
        """Get customer profile by ID"""
        
        customer = self._customer_dao.find_by_id(customer_id)
        
        if not customer:
            raise ValueError('Customer not found')
        
        return CustomerResponseDTO.from_model(customer)
    
    def update_profile(self, customer_id: int, data: dict) -> CustomerResponseDTO:
        """Update customer profile"""
        
        customer = self._customer_dao.find_by_id(customer_id)
        
        if not customer:
            raise ValueError('Customer not found')
        
        # Update allowed fields
        allowed_fields = [
            'first_name', 'last_name', 'date_of_birth',
            'address', 'city', 'state', 'pincode'
        ]
        
        for field in allowed_fields:
            if field in data and data[field] is not None:
                setattr(customer, field, data[field])
        
        updated_customer = self._customer_dao.update(customer)
        
        return CustomerResponseDTO.from_model(updated_customer)
    
    def change_password(self, customer_id: int, old_password: str, new_password: str) -> bool:
        """Change customer password"""
        
        customer = self._customer_dao.find_by_id(customer_id)
        
        if not customer:
            raise ValueError('Customer not found')
        
        if not customer.check_password(old_password):
            raise ValueError('Current password is incorrect')
        
        if len(new_password) < 8:
            raise ValueError('New password must be at least 8 characters')
        
        customer.set_password(new_password)
        self._customer_dao.update(customer)
        
        return True
    
    def deactivate_account(self, customer_id: int) -> bool:
        """Deactivate customer account"""
        
        customer = self._customer_dao.find_by_id(customer_id)
        
        if not customer:
            raise ValueError('Customer not found')
        
        customer.is_active = False
        self._customer_dao.update(customer)
        
        return True
