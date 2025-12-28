export interface LoginRequestDTO {
  email: string;
  password: string;
}

export interface LoginResponseDTO {
  success: boolean;
  message: string;
  data?: {
    access_token: string;
    refresh_token: string;
    customer: {
      id: number;
      email: string;
      full_name: string;
    };
  };
}
