export interface SignupRequestDTO {
  email: string;
  mobile_number: string;
  password: string;
  first_name: string;
  last_name: string;
}

export interface SignupResponseDTO {
  success: boolean;
  message: string;
  customer_id?: number;
  email?: string;
}
