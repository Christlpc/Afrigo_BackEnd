export type UserType = 'client' | 'driver' | 'merchant' | 'livreur' | 'admin';
export type UserStatus = 'pending' | 'active' | 'suspended' | 'banned';
export type KycStatus = 'pending' | 'verified' | 'rejected' | 'expired';
export type VehicleType = 'taxi' | 'moto' | 'vip';
export type RouteType = 'taxi' | 'moto' | 'vip' | 'carpool';
export type VipClass = 'business' | 'luxe' | 'xl';
export type RouteStatus = 'pending' | 'accepted' | 'pickup' | 'in_transit' | 'completed' | 'cancelled';
export type PaymentMethod = 'cash' | 'mobile_money' | 'card' | 'wallet';
export type PaymentStatus = 'pending' | 'completed' | 'failed' | 'cancelled';
export type TransactionType = 'credit' | 'debit' | 'commission' | 'withdrawal' | 'refund';

export interface User {
  id: number;
  email: string;
  phone: string;
  phone_verified: boolean;
  password_hash: string;
  first_name: string | null;
  last_name: string | null;
  profile_picture_url: string | null;
  user_type: UserType;
  status: UserStatus;
  kyc_status: KycStatus;
  language_preference: string;
  created_at: Date;
  updated_at: Date;
  deleted_at: Date | null;
}

export interface Address {
  id: number;
  user_id: number | null;
  address_label: string | null;
  full_address: string;
  latitude: number | null;
  longitude: number | null;
  location: string | null; // PostGIS geometry
  city: string | null;
  district: string | null;
  postcode: string | null;
  additional_info: string | null;
  is_favorite: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface Route {
  id: number;
  client_id: number;
  driver_id: number | null;
  pickup_address_id: number;
  dropoff_address_id: number;
  pickup_location: string | null; // PostGIS geometry
  dropoff_location: string | null; // PostGIS geometry
  route_type: RouteType;
  vip_class: VipClass | null;
  status: RouteStatus;
  scheduled_at: Date | null;
  started_at: Date | null;
  completed_at: Date | null;
  cancelled_at: Date | null;
  cancellation_reason: string | null;
  cancelled_by: string | null;
  estimated_distance: number | null;
  estimated_duration: number | null;
  actual_distance: number | null;
  actual_duration: number | null;
  base_fare: number | null;
  distance_fare: number | null;
  time_fare: number | null;
  traffic_multiplier: number;
  weather_surcharge: number;
  waiting_fee: number;
  vip_multiplier: number;
  total_fare: number | null;
  commission_amount: number | null;
  commission_rate: number | null;
  driver_earnings: number | null;
  payment_method: PaymentMethod | null;
  payment_status: PaymentStatus;
  notes: string | null;
  third_party_order: boolean;
  third_party_name: string | null;
  third_party_phone: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface Wallet {
  id: number;
  user_id: number;
  balance: number;
  pending_balance: number;
  total_earned: number;
  last_withdrawal_date: Date | null;
  created_at: Date;
  updated_at: Date;
}

export interface WalletTransaction {
  id: number;
  wallet_id: number;
  transaction_type: TransactionType;
  amount: number;
  reference_type: string | null;
  reference_id: number | null;
  description: string | null;
  status: string;
  created_at: Date;
}

export interface ClientProfile {
  id: number;
  user_id: number;
  favorite_addresses: any; // JSONB
  emergency_contact: string | null;
  total_trips: number;
  total_spent: number;
  average_rating: number | null;
  created_at: Date;
  updated_at: Date;
}

