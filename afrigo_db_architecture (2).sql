-- ============================================================================
-- ARCHITECTURE BASE DE DONNÉES AfriGo - PostgreSQL 14+
-- Compatible: PostgreSQL 12, 13, 14, 15, 16
-- ============================================================================

-- ============================================================================
-- 1. EXTENSIONS NÉCESSAIRES
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- ============================================================================
-- 2. TYPES ÉNUMÉRÉS
-- ============================================================================

CREATE TYPE user_type_enum AS ENUM ('client', 'driver', 'merchant', 'livreur', 'admin');
CREATE TYPE user_status_enum AS ENUM ('pending', 'active', 'suspended', 'banned');
CREATE TYPE kyc_status_enum AS ENUM ('pending', 'verified', 'rejected', 'expired');
CREATE TYPE document_type_enum AS ENUM ('cni', 'permis', 'carte_grise', 'assurance');
CREATE TYPE vehicle_type_enum AS ENUM ('taxi', 'moto', 'vip');
CREATE TYPE route_type_enum AS ENUM ('taxi', 'moto', 'vip', 'carpool');
CREATE TYPE vip_class_enum AS ENUM ('business', 'luxe', 'xl');
CREATE TYPE route_status_enum AS ENUM ('pending', 'accepted', 'pickup', 'in_transit', 'completed', 'cancelled');
CREATE TYPE payment_method_enum AS ENUM ('cash', 'mobile_money', 'card');
CREATE TYPE payment_status_enum AS ENUM ('pending', 'completed', 'failed', 'cancelled');
CREATE TYPE delivery_status_enum AS ENUM ('pending', 'accepted', 'pickup', 'in_transit', 'delivered', 'failed', 'cancelled');
CREATE TYPE delivery_type_enum AS ENUM ('standard', 'express');
CREATE TYPE order_status_enum AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled');
CREATE TYPE subscription_tier_enum AS ENUM ('petit', 'moyen', 'grand', 'premium', 'standard');
CREATE TYPE business_category_enum AS ENUM ('restaurant', 'alimentation', 'ecommerce', 'services');
CREATE TYPE transaction_type_enum AS ENUM ('credit', 'debit', 'commission', 'withdrawal', 'refund');
CREATE TYPE dispute_status_enum AS ENUM ('open', 'under_review', 'resolved', 'closed');
CREATE TYPE ticket_priority_enum AS ENUM ('low', 'normal', 'high', 'urgent');
CREATE TYPE ticket_status_enum AS ENUM ('open', 'in_progress', 'waiting_user', 'resolved', 'closed');

-- ============================================================================
-- 3. TABLES DE CONFIGURATION SYSTÈME
-- ============================================================================

CREATE TABLE system_config (
    id BIGSERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_system_config_key ON system_config(key);

CREATE TABLE fuel_index (
    id BIGSERIAL PRIMARY KEY,
    price_per_liter NUMERIC(10, 4) NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fuel_index_valid_period ON fuel_index(valid_from, valid_to);

-- ============================================================================
-- 4. GESTION DES UTILISATEURS
-- ============================================================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    phone_verified BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    profile_picture_url TEXT,
    user_type user_type_enum NOT NULL,
    status user_status_enum DEFAULT 'pending',
    kyc_status kyc_status_enum DEFAULT 'pending',
    language_preference VARCHAR(10) DEFAULT 'FR',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_type ON users(user_type);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_kyc_status ON users(kyc_status);
CREATE INDEX idx_users_created_at ON users(created_at);

CREATE TABLE user_authentication (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    otp_secret VARCHAR(32),
    two_fa_enabled BOOLEAN DEFAULT FALSE,
    two_fa_method VARCHAR(50),
    last_login TIMESTAMP WITH TIME ZONE,
    login_attempts INT DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_devices (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    device_type VARCHAR(50),
    app_version VARCHAR(20),
    fcm_token TEXT,
    push_notifications_enabled BOOLEAN DEFAULT TRUE,
    last_active TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX idx_user_devices_fcm_token ON user_devices(fcm_token);

-- ============================================================================
-- 5. VÉRIFICATION KYC (Know Your Customer)
-- ============================================================================

CREATE TABLE kyc_documents (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    document_type document_type_enum NOT NULL,
    document_number VARCHAR(100) UNIQUE NOT NULL,
    file_url TEXT NOT NULL,
    file_hash VARCHAR(64),
    expiry_date DATE,
    verified BOOLEAN DEFAULT FALSE,
    rejected_reason TEXT,
    verified_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kyc_documents_user_id ON kyc_documents(user_id);
CREATE INDEX idx_kyc_documents_type ON kyc_documents(document_type);
CREATE INDEX idx_kyc_documents_verified ON kyc_documents(verified);

-- ============================================================================
-- 6. PROFILS UTILISATEURS SPÉCIALISÉS
-- ============================================================================

CREATE TABLE client_profile (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    favorite_addresses JSONB,
    emergency_contact VARCHAR(20),
    total_trips INT DEFAULT 0,
    total_spent NUMERIC(15, 2) DEFAULT 0,
    average_rating NUMERIC(3, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_client_profile_rating ON client_profile(average_rating);

CREATE TABLE driver_profile (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type vehicle_type_enum NOT NULL,
    vehicle_registration VARCHAR(50) UNIQUE NOT NULL,
    vehicle_brand VARCHAR(100),
    vehicle_model VARCHAR(100),
    vehicle_color VARCHAR(50),
    vehicle_year INT,
    vehicle_photo_url TEXT,
    license_plate VARCHAR(50) UNIQUE NOT NULL,
    bank_account_name VARCHAR(100),
    bank_account_number VARCHAR(50),
    bank_name VARCHAR(100),
    mobile_money_operator VARCHAR(50),
    mobile_money_account VARCHAR(20),
    insurance_provider VARCHAR(100),
    insurance_policy_number VARCHAR(50) UNIQUE,
    insurance_expiry DATE,
    total_earnings NUMERIC(15, 2) DEFAULT 0,
    total_trips INT DEFAULT 0,
    average_rating NUMERIC(3, 2),
    subscription_tier subscription_tier_enum,
    subscription_end_date TIMESTAMP WITH TIME ZONE,
    subscription_auto_renew BOOLEAN DEFAULT FALSE,
    online_status BOOLEAN DEFAULT FALSE,
    current_location geometry(POINT, 4326),
    location_updated_at TIMESTAMP WITH TIME ZONE,
    acceptance_rate NUMERIC(5, 2),
    cancellation_rate NUMERIC(5, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_driver_profile_vehicle_type ON driver_profile(vehicle_type);
CREATE INDEX idx_driver_profile_online_status ON driver_profile(online_status);
CREATE INDEX idx_driver_profile_location ON driver_profile USING GIST(current_location);
CREATE INDEX idx_driver_profile_subscription_end ON driver_profile(subscription_end_date);
CREATE INDEX idx_driver_profile_rating ON driver_profile(average_rating);

CREATE TABLE merchant_profile (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    business_category business_category_enum,
    business_description TEXT,
    business_logo_url TEXT,
    business_website VARCHAR(255),
    subscription_tier subscription_tier_enum,
    subscription_end_date TIMESTAMP WITH TIME ZONE,
    subscription_auto_renew BOOLEAN DEFAULT FALSE,
    total_sales NUMERIC(15, 2) DEFAULT 0,
    commission_rate NUMERIC(5, 2),
    store_count INT DEFAULT 1,
    average_rating NUMERIC(3, 2),
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_merchant_profile_business_category ON merchant_profile(business_category);
CREATE INDEX idx_merchant_profile_subscription_end ON merchant_profile(subscription_end_date);
CREATE INDEX idx_merchant_profile_rating ON merchant_profile(average_rating);

CREATE TABLE livreur_profile (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    delivery_capacity VARCHAR(50),
    transport_type vehicle_type_enum,
    total_deliveries INT DEFAULT 0,
    total_earnings NUMERIC(15, 2) DEFAULT 0,
    average_rating NUMERIC(3, 2),
    online_status BOOLEAN DEFAULT FALSE,
    current_location geometry(POINT, 4326),
    location_updated_at TIMESTAMP WITH TIME ZONE,
    acceptance_rate NUMERIC(5, 2),
    cancellation_rate NUMERIC(5, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_livreur_profile_transport_type ON livreur_profile(transport_type);
CREATE INDEX idx_livreur_profile_online_status ON livreur_profile(online_status);
CREATE INDEX idx_livreur_profile_location ON livreur_profile USING GIST(current_location);

-- ============================================================================
-- 7. ADRESSES & GÉOLOCALISATION
-- ============================================================================

CREATE TABLE addresses (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    address_label VARCHAR(100),
    full_address TEXT NOT NULL,
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    location geometry(POINT, 4326),
    city VARCHAR(100),
    district VARCHAR(100),
    postcode VARCHAR(20),
    additional_info TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_addresses_user_id ON addresses(user_id);
CREATE INDEX idx_addresses_location ON addresses USING GIST(location);
CREATE INDEX idx_addresses_favorite ON addresses(is_favorite);

CREATE TABLE points_of_interest (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    poi_type VARCHAR(50),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    location geometry(POINT, 4326),
    city VARCHAR(100),
    description TEXT,
    source VARCHAR(50),
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_points_of_interest_location ON points_of_interest USING GIST(location);
CREATE INDEX idx_points_of_interest_type ON points_of_interest(poi_type);

-- ============================================================================
-- 8. TRANSPORT & TRAJETS
-- ============================================================================

CREATE TABLE routes (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    driver_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    pickup_address_id BIGINT NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    dropoff_address_id BIGINT NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    pickup_location geometry(POINT, 4326),
    dropoff_location geometry(POINT, 4326),
    route_type route_type_enum NOT NULL,
    vip_class vip_class_enum,
    status route_status_enum DEFAULT 'pending',
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT,
    cancelled_by VARCHAR(50),
    estimated_distance NUMERIC(8, 2),
    estimated_duration INT,
    actual_distance NUMERIC(8, 2),
    actual_duration INT,
    base_fare NUMERIC(10, 4),
    distance_fare NUMERIC(10, 4),
    time_fare NUMERIC(10, 4),
    traffic_multiplier NUMERIC(4, 2) DEFAULT 1.0,
    weather_surcharge NUMERIC(10, 4) DEFAULT 0,
    waiting_fee NUMERIC(10, 4) DEFAULT 0,
    vip_multiplier NUMERIC(4, 2) DEFAULT 1.0,
    total_fare NUMERIC(10, 4),
    commission_amount NUMERIC(10, 4),
    commission_rate NUMERIC(5, 2),
    driver_earnings NUMERIC(10, 4),
    payment_method payment_method_enum,
    payment_status payment_status_enum DEFAULT 'pending',
    notes TEXT,
    third_party_order BOOLEAN DEFAULT FALSE,
    third_party_name VARCHAR(100),
    third_party_phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_routes_client_id ON routes(client_id);
CREATE INDEX idx_routes_driver_id ON routes(driver_id);
CREATE INDEX idx_routes_status ON routes(status);
CREATE INDEX idx_routes_created_at ON routes(created_at);
CREATE INDEX idx_routes_payment_status ON routes(payment_status);
CREATE INDEX idx_routes_pickup_location ON routes USING GIST(pickup_location);
CREATE INDEX idx_routes_dropoff_location ON routes USING GIST(dropoff_location);

CREATE TABLE route_tracking (
    id BIGSERIAL PRIMARY KEY,
    route_id BIGINT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    driver_location geometry(POINT, 4326),
    speed NUMERIC(6, 2),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_route_tracking_route_id ON route_tracking(route_id);
CREATE INDEX idx_route_tracking_timestamp ON route_tracking(timestamp);
CREATE INDEX idx_route_tracking_location ON route_tracking USING GIST(driver_location);

CREATE TABLE school_professional_contracts (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contract_name VARCHAR(255) NOT NULL,
    contract_type VARCHAR(50),
    pickup_location_id BIGINT NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    dropoff_location_id BIGINT NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    vehicle_type vehicle_type_enum,
    frequency VARCHAR(50),
    time_start TIME,
    time_end TIME,
    max_passengers INT,
    monthly_price NUMERIC(15, 2),
    driver_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'active',
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_school_contracts_client_id ON school_professional_contracts(client_id);
CREATE INDEX idx_school_contracts_status ON school_professional_contracts(status);

-- ============================================================================
-- 9. LIVRAISON
-- ============================================================================

CREATE TABLE deliveries (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    client_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    livreur_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    pickup_address_id BIGINT NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    dropoff_address_id BIGINT NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    pickup_location geometry(POINT, 4326),
    dropoff_location geometry(POINT, 4326),
    status delivery_status_enum DEFAULT 'pending',
    delivery_type delivery_type_enum,
    scheduled_pickup_time TIMESTAMP WITH TIME ZONE,
    actual_pickup_time TIMESTAMP WITH TIME ZONE,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    actual_delivery_time TIMESTAMP WITH TIME ZONE,
    estimated_distance NUMERIC(8, 2),
    actual_distance NUMERIC(8, 2),
    base_delivery_fee NUMERIC(10, 4),
    distance_fee NUMERIC(10, 4),
    insurance_fee NUMERIC(10, 4) DEFAULT 0,
    total_delivery_fee NUMERIC(10, 4),
    livreur_commission NUMERIC(10, 4),
    afrigo_commission NUMERIC(10, 4),
    payment_method payment_method_enum,
    payment_status payment_status_enum DEFAULT 'pending',
    proof_of_delivery_code VARCHAR(50),
    signature_url TEXT,
    photo_url TEXT,
    recipient_name VARCHAR(100),
    recipient_phone VARCHAR(20),
    special_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_deliveries_order_id ON deliveries(order_id);
CREATE INDEX idx_deliveries_client_id ON deliveries(client_id);
CREATE INDEX idx_deliveries_livreur_id ON deliveries(livreur_id);
CREATE INDEX idx_deliveries_status ON deliveries(status);
CREATE INDEX idx_deliveries_pickup_location ON deliveries USING GIST(pickup_location);
CREATE INDEX idx_deliveries_dropoff_location ON deliveries USING GIST(dropoff_location);

-- ============================================================================
-- 10. SERVICES CONNECTÉS & COMMANDES
-- ============================================================================

CREATE TABLE merchants_stores (
    id BIGSERIAL PRIMARY KEY,
    merchant_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    store_name VARCHAR(255) NOT NULL,
    address_id BIGINT NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    store_location geometry(POINT, 4326),
    phone VARCHAR(20),
    opening_hours JSONB,
    is_open BOOLEAN DEFAULT TRUE,
    average_rating NUMERIC(3, 2),
    total_orders INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_merchants_stores_merchant_id ON merchants_stores(merchant_id);
CREATE INDEX idx_merchants_stores_location ON merchants_stores USING GIST(store_location);

CREATE TABLE product_categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon_url TEXT,
    display_order INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_product_categories_slug ON product_categories(slug);

CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    merchant_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    store_id BIGINT REFERENCES merchants_stores(id) ON DELETE CASCADE,
    category_id BIGINT NOT NULL REFERENCES product_categories(id) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    photo_url TEXT,
    price NUMERIC(10, 4) NOT NULL,
    original_price NUMERIC(10, 4),
    is_available BOOLEAN DEFAULT TRUE,
    in_stock INT DEFAULT 1,
    preparation_time_minutes INT,
    rating NUMERIC(3, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_merchant_id ON products(merchant_id);
CREATE INDEX idx_products_store_id ON products(store_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_available ON products(is_available);

CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    merchant_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    store_id BIGINT NOT NULL REFERENCES merchants_stores(id) ON DELETE RESTRICT,
    delivery_address_id BIGINT NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
    delivery_type VARCHAR(50),
    status order_status_enum DEFAULT 'pending',
    order_number VARCHAR(50) UNIQUE NOT NULL,
    subtotal NUMERIC(15, 2),
    delivery_fee NUMERIC(10, 4) DEFAULT 0,
    discount NUMERIC(10, 4) DEFAULT 0,
    taxes NUMERIC(10, 4) DEFAULT 0,
    total_amount NUMERIC(15, 2),
    payment_method payment_method_enum,
    payment_status payment_status_enum DEFAULT 'pending',
    special_instructions TEXT,
    estimated_preparation_time INT,
    scheduled_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_client_id ON orders(client_id);
CREATE INDEX idx_orders_merchant_id ON orders(merchant_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_order_number ON orders(order_number);

CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity INT NOT NULL,
    unit_price NUMERIC(10, 4),
    total_price NUMERIC(15, 2),
    special_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Foreign key for deliveries.order_id (defined after orders table)
ALTER TABLE deliveries
ADD CONSTRAINT fk_deliveries_order_id
FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE;

-- ============================================================================
-- 11. PAIEMENTS & PORTEFEUILLE
-- ============================================================================

CREATE TABLE payment_methods (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    method_type payment_method_enum NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    card_last_digits VARCHAR(4),
    card_brand VARCHAR(50),
    card_expiry VARCHAR(7),
    mobile_money_operator VARCHAR(50),
    mobile_money_account VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);
CREATE INDEX idx_payment_methods_default ON payment_methods(is_default);

CREATE TABLE wallet (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    balance NUMERIC(15, 2) DEFAULT 0,
    pending_balance NUMERIC(15, 2) DEFAULT 0,
    total_earned NUMERIC(15, 2) DEFAULT 0,
    last_withdrawal_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wallet_user_id ON wallet(user_id);

CREATE TABLE wallet_transactions (
    id BIGSERIAL PRIMARY KEY,
    wallet_id BIGINT NOT NULL REFERENCES wallet(id) ON DELETE CASCADE,
    transaction_type transaction_type_enum NOT NULL,
    amount NUMERIC(15, 2),
    reference_type VARCHAR(50),
    reference_id BIGINT,
    description TEXT,
    status VARCHAR(50) DEFAULT 'completed',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_transactions_type ON wallet_transactions(transaction_type);
CREATE INDEX idx_wallet_transactions_created_at ON wallet_transactions(created_at);

CREATE TABLE payment_transactions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    amount NUMERIC(15, 4),
    currency VARCHAR(3) DEFAULT 'XAF',
    transaction_type VARCHAR(50),
    reference_type VARCHAR(50),
    reference_id BIGINT,
    payment_method_id BIGINT REFERENCES payment_methods(id) ON DELETE SET NULL,
    external_transaction_id VARCHAR(255),
    provider VARCHAR(50),
    status payment_status_enum DEFAULT 'pending',
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX idx_payment_transactions_external_id ON payment_transactions(external_transaction_id);
CREATE INDEX idx_payment_transactions_created_at ON payment_transactions(created_at);

-- ============================================================================
-- 12. RATINGS & AVIS
-- ============================================================================

CREATE TABLE ratings (
    id BIGSERIAL PRIMARY KEY,
    rater_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ratee_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating_type VARCHAR(50),
    reference_type VARCHAR(50),
    reference_id BIGINT,
    rating NUMERIC(3, 2) NOT NULL,
    review_text TEXT,
    photos JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(rater_id, ratee_id, reference_id)
);

CREATE INDEX idx_ratings_ratee_id ON ratings(ratee_id);
CREATE INDEX idx_ratings_type ON ratings(rating_type);
CREATE INDEX idx_ratings_created_at ON ratings(created_at);

-- ============================================================================
-- 13. PUBLICITÉS
-- ============================================================================

CREATE TABLE ad_campaigns (
    id BIGSERIAL PRIMARY KEY,
    merchant_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    destination_url TEXT,
    ad_package VARCHAR(50),
    campaign_type VARCHAR(50),
    budget NUMERIC(15, 2),
    spent NUMERIC(15, 2) DEFAULT 0,
    impressions INT DEFAULT 0,
    clicks INT DEFAULT 0,
    status VARCHAR(50) DEFAULT 'pending',
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ad_campaigns_merchant_id ON ad_campaigns(merchant_id);
CREATE INDEX idx_ad_campaigns_status ON ad_campaigns(status);

-- ============================================================================
-- 14. LITIGES & SUPPORT
-- ============================================================================

CREATE TABLE disputes (
    id BIGSERIAL PRIMARY KEY,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    initiator_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    responder_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    description TEXT,
    status dispute_status_enum DEFAULT 'open',
    resolution_type VARCHAR(50),
    refund_amount NUMERIC(15, 2),
    admin_notes TEXT,
    assigned_to BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_disputes_status ON disputes(status);
CREATE INDEX idx_disputes_created_at ON disputes(created_at);
CREATE INDEX idx_disputes_initiator_id ON disputes(initiator_id);

CREATE TABLE support_tickets (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ticket_number VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(50),
    priority ticket_priority_enum DEFAULT 'normal',
    subject VARCHAR(255),
    description TEXT,
    status ticket_status_enum DEFAULT 'open',
    assigned_to BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_status ON support_tickets(status);
CREATE INDEX idx_support_tickets_priority ON support_tickets(priority);

CREATE TABLE support_messages (
    id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    attachments JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_support_messages_ticket_id ON support_messages(ticket_id);
CREATE INDEX idx_support_messages_sender_id ON support_messages(sender_id);

-- ============================================================================
-- 15. SOS & SÉCURITÉ
-- ============================================================================

CREATE TABLE sos_alerts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    route_id BIGINT REFERENCES routes(id) ON DELETE SET NULL,
    alert_type VARCHAR(50),
    location geometry(POINT, 4326),
    description TEXT,
    emergency_contacts_notified JSONB,
    status VARCHAR(50) DEFAULT 'active',
    responder_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_sos_alerts_user_id ON sos_alerts(user_id);
CREATE INDEX idx_sos_alerts_status ON sos_alerts(status);
CREATE INDEX idx_sos_alerts_location ON sos_alerts USING GIST(location);

CREATE TABLE emergency_contacts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_name VARCHAR(100),
    contact_phone VARCHAR(20),
    relationship VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_emergency_contacts_user_id ON emergency_contacts(user_id);

-- ============================================================================
-- 16. NOTIFICATIONS
-- ============================================================================

CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50),
    title VARCHAR(255),
    message TEXT,
    reference_type VARCHAR(50),
    reference_id BIGINT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    action_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- ============================================================================
-- 17. AUDIT & LOGS
-- ============================================================================

CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    action_type VARCHAR(100),
    entity_type VARCHAR(50),
    entity_id BIGINT,
    old_values JSONB,
    new_values JSONB,
    description TEXT,
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_admin_id ON audit_logs(admin_id);
CREATE INDEX idx_audit_logs_entity_type ON audit_logs(entity_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

CREATE TABLE system_logs (
    id BIGSERIAL PRIMARY KEY,
    log_level VARCHAR(20),
    log_source VARCHAR(100),
    message TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_system_logs_level ON system_logs(log_level);
CREATE INDEX idx_system_logs_created_at ON system_logs(created_at);

-- ============================================================================
-- 18. ANALYTICS & STATISTIQUES
-- ============================================================================

CREATE TABLE daily_metrics (
    id BIGSERIAL PRIMARY KEY,
    metric_date DATE NOT NULL UNIQUE,
    total_routes INT DEFAULT 0,
    completed_routes INT DEFAULT 0,
    cancelled_routes INT DEFAULT 0,
    total_deliveries INT DEFAULT 0,
    completed_deliveries INT DEFAULT 0,
    total_orders INT DEFAULT 0,
    completed_orders INT DEFAULT 0,
    total_revenue NUMERIC(15, 2) DEFAULT 0,
    total_commissions NUMERIC(15, 2) DEFAULT 0,
    active_drivers INT DEFAULT 0,
    active_livreurs INT DEFAULT 0,
    new_merchants INT DEFAULT 0,
    new_clients INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_daily_metrics_date ON daily_metrics(metric_date);

CREATE TABLE cashflow_tracking (
    id BIGSERIAL PRIMARY KEY,
    transaction_date DATE NOT NULL,
    transaction_type VARCHAR(50),
    amount NUMERIC(15, 2),
    method VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending',
    reconciled BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cashflow_tracking_date ON cashflow_tracking(transaction_date);
CREATE INDEX idx_cashflow_tracking_status ON cashflow_tracking(status);

-- ============================================================================
-- 19. PROMOTIONS & COUPONS
-- ============================================================================

CREATE TABLE coupons (
    id BIGSERIAL PRIMARY KEY,
    coupon_code VARCHAR(50) UNIQUE NOT NULL,
    coupon_type VARCHAR(50),
    discount_value NUMERIC(10, 4),
    max_discount NUMERIC(10, 4),
    min_order_amount NUMERIC(10, 4),
    usage_limit INT,
    usage_count INT DEFAULT 0,
    valid_from TIMESTAMP WITH TIME ZONE,
    valid_until TIMESTAMP WITH TIME ZONE,
    applicable_categories JSONB,
    status VARCHAR(50) DEFAULT 'active',
    created_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_coupons_code ON coupons(coupon_code);
CREATE INDEX idx_coupons_valid_period ON coupons(valid_from, valid_until);

CREATE TABLE user_coupon_usage (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    coupon_id BIGINT NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
    order_id BIGINT REFERENCES orders(id) ON DELETE SET NULL,
    discount_amount NUMERIC(10, 4),
    used_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_coupon_usage_user_id ON user_coupon_usage(user_id);
CREATE INDEX idx_user_coupon_usage_coupon_id ON user_coupon_usage(coupon_id);

-- ============================================================================
-- 20. FEEDBACK & SURVEYS
-- ============================================================================

CREATE TABLE feedback (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feedback_type VARCHAR(50),
    category VARCHAR(100),
    title VARCHAR(255),
    description TEXT,
    attachments JSONB,
    status VARCHAR(50) DEFAULT 'new',
    priority VARCHAR(50) DEFAULT 'normal',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_feedback_user_id ON feedback(user_id);
CREATE INDEX idx_feedback_status ON feedback(status);

-- ============================================================================
-- 21. BLOCKLIST & COMPLIANCE
-- ============================================================================

CREATE TABLE blocklist (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    blocker_user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_blocklist_user_id ON blocklist(user_id);
CREATE INDEX idx_blocklist_blocker_user_id ON blocklist(blocker_user_id);

CREATE TABLE suspicious_activity_log (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50),
    severity VARCHAR(50) DEFAULT 'low',
    description TEXT,
    action_taken VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_suspicious_activity_log_user_id ON suspicious_activity_log(user_id);
CREATE INDEX idx_suspicious_activity_log_severity ON suspicious_activity_log(severity);

-- ============================================================================
-- 22. DOCUMENTS & FICHIERS
-- ============================================================================

CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(50),
    document_name VARCHAR(255),
    file_url TEXT,
    file_hash VARCHAR(64),
    mime_type VARCHAR(50),
    size_bytes BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_type ON documents(document_type);

-- ============================================================================
-- 23. SESSIONS & SÉCURITÉ
-- ============================================================================

CREATE TABLE user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    ip_address VARCHAR(50),
    user_agent TEXT,
    device_id VARCHAR(255),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);

-- ============================================================================
-- 24. BACKGROUND JOBS
-- ============================================================================

CREATE TABLE scheduled_jobs (
    id BIGSERIAL PRIMARY KEY,
    job_type VARCHAR(100),
    job_status VARCHAR(50) DEFAULT 'pending',
    reference_type VARCHAR(50),
    reference_id BIGINT,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    retry_count INT DEFAULT 0,
    max_retries INT DEFAULT 3,
    error_message TEXT,
    result JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scheduled_jobs_status ON scheduled_jobs(job_status);
CREATE INDEX idx_scheduled_jobs_scheduled_at ON scheduled_jobs(scheduled_at);

-- ============================================================================
-- VUES UTILES POUR LES REQUÊTES FRÉQUENTES
-- ============================================================================

CREATE VIEW active_drivers AS
SELECT 
    d.id,
    u.id AS user_id,
    u.email,
    u.phone,
    d.vehicle_type,
    d.online_status,
    d.current_location,
    d.average_rating,
    d.total_trips,
    d.acceptance_rate,
    d.cancellation_rate
FROM driver_profile d
INNER JOIN users u ON d.user_id = u.id
WHERE u.status = 'active' 
    AND d.online_status = TRUE 
    AND u.kyc_status = 'verified';

CREATE VIEW merchant_performance AS
SELECT 
    m.id,
    u.email,
    m.business_name,
    m.business_category,
    m.subscription_tier,
    m.total_sales,
    m.average_rating,
    COUNT(DISTINCT o.id) AS total_orders,
    COALESCE(AVG(CAST(r.rating AS NUMERIC)), 0) AS avg_review_rating
FROM merchant_profile m
INNER JOIN users u ON m.user_id = u.id
LEFT JOIN orders o ON m.id = o.merchant_id AND o.created_at > CURRENT_TIMESTAMP - INTERVAL '30 days'
LEFT JOIN ratings r ON u.id = r.ratee_id AND r.rating_type = 'merchant'
GROUP BY m.id, u.email, m.business_name, m.business_category, m.subscription_tier, m.total_sales, m.average_rating;

CREATE VIEW driver_earnings_summary AS
SELECT 
    d.id,
    u.email,
    d.vehicle_type,
    d.total_earnings,
    d.total_trips,
    COUNT(r.id) AS trips_last_30_days,
    COALESCE(SUM(r.driver_earnings), 0) AS earnings_last_30_days
FROM driver_profile d
INNER JOIN users u ON d.user_id = u.id
LEFT JOIN routes r ON d.user_id = r.driver_id AND r.created_at > CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY d.id, u.email, d.vehicle_type, d.total_earnings, d.total_trips;

-- ============================================================================
-- TRIGGERS POUR L'INTÉGRITÉ DES DONNÉES
-- ============================================================================

-- Fonction pour mettre à jour la moyenne des ratings
CREATE OR REPLACE FUNCTION update_rating_average()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.rating_type = 'driver' THEN
        UPDATE driver_profile 
        SET average_rating = (
            SELECT AVG(CAST(rating AS NUMERIC)) FROM ratings 
            WHERE ratee_id = NEW.ratee_id AND rating_type = 'driver'
        )
        WHERE user_id = NEW.ratee_id;
    ELSIF NEW.rating_type = 'merchant' THEN
        UPDATE merchant_profile 
        SET average_rating = (
            SELECT AVG(CAST(rating AS NUMERIC)) FROM ratings 
            WHERE ratee_id = NEW.ratee_id AND rating_type = 'merchant'
        )
        WHERE user_id = NEW.ratee_id;
    ELSIF NEW.rating_type = 'client' THEN
        UPDATE client_profile 
        SET average_rating = (
            SELECT AVG(CAST(rating AS NUMERIC)) FROM ratings 
            WHERE ratee_id = NEW.ratee_id AND rating_type = 'client'
        )
        WHERE user_id = NEW.ratee_id;
    END IF;
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_rating_average ON ratings;
CREATE TRIGGER trg_update_rating_average
AFTER INSERT ON ratings
FOR EACH ROW
EXECUTE FUNCTION update_rating_average();

-- Fonction pour calculer les commissions
CREATE OR REPLACE FUNCTION calculate_route_commission()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.status = 'completed' AND OLD.status IS DISTINCT FROM NEW.status THEN
        NEW.commission_amount := NEW.total_fare * (NEW.commission_rate / 100);
        NEW.driver_earnings := NEW.total_fare - NEW.commission_amount;
    END IF;
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_calculate_route_commission ON routes;
CREATE TRIGGER trg_calculate_route_commission
BEFORE UPDATE ON routes
FOR EACH ROW
EXECUTE FUNCTION calculate_route_commission();

-- Fonction pour mettre à jour le timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_update_users_timestamp ON users;
CREATE TRIGGER trg_update_users_timestamp 
BEFORE UPDATE ON users
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_routes_timestamp ON routes;
CREATE TRIGGER trg_update_routes_timestamp 
BEFORE UPDATE ON routes
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_orders_timestamp ON orders;
CREATE TRIGGER trg_update_orders_timestamp 
BEFORE UPDATE ON orders
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_driver_profile_timestamp ON driver_profile;
CREATE TRIGGER trg_update_driver_profile_timestamp 
BEFORE UPDATE ON driver_profile
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_merchant_profile_timestamp ON merchant_profile;
CREATE TRIGGER trg_update_merchant_profile_timestamp 
BEFORE UPDATE ON merchant_profile
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_addresses_timestamp ON addresses;
CREATE TRIGGER trg_update_addresses_timestamp 
BEFORE UPDATE ON addresses
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_deliveries_timestamp ON deliveries;
CREATE TRIGGER trg_update_deliveries_timestamp 
BEFORE UPDATE ON deliveries
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_merchants_stores_timestamp ON merchants_stores;
CREATE TRIGGER trg_update_merchants_stores_timestamp 
BEFORE UPDATE ON merchants_stores
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_products_timestamp ON products;
CREATE TRIGGER trg_update_products_timestamp 
BEFORE UPDATE ON products
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_payment_methods_timestamp ON payment_methods;
CREATE TRIGGER trg_update_payment_methods_timestamp 
BEFORE UPDATE ON payment_methods
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_wallet_timestamp ON wallet;
CREATE TRIGGER trg_update_wallet_timestamp 
BEFORE UPDATE ON wallet
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_livreur_profile_timestamp ON livreur_profile;
CREATE TRIGGER trg_update_livreur_profile_timestamp 
BEFORE UPDATE ON livreur_profile
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_client_profile_timestamp ON client_profile;
CREATE TRIGGER trg_update_client_profile_timestamp 
BEFORE UPDATE ON client_profile
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_support_tickets_timestamp ON support_tickets;
CREATE TRIGGER trg_update_support_tickets_timestamp 
BEFORE UPDATE ON support_tickets
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_coupons_timestamp ON coupons;
CREATE TRIGGER trg_update_coupons_timestamp 
BEFORE UPDATE ON coupons
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_feedback_timestamp ON feedback;
CREATE TRIGGER trg_update_feedback_timestamp 
BEFORE UPDATE ON feedback
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_ad_campaigns_timestamp ON ad_campaigns;
CREATE TRIGGER trg_update_ad_campaigns_timestamp 
BEFORE UPDATE ON ad_campaigns
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_disputes_timestamp ON disputes;
CREATE TRIGGER trg_update_disputes_timestamp 
BEFORE UPDATE ON disputes
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_payment_transactions_timestamp ON payment_transactions;
CREATE TRIGGER trg_update_payment_transactions_timestamp 
BEFORE UPDATE ON payment_transactions
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_wallet_transactions_timestamp ON wallet_transactions;
CREATE TRIGGER trg_update_wallet_transactions_timestamp 
BEFORE UPDATE ON wallet_transactions
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

DROP TRIGGER IF EXISTS trg_update_scheduled_jobs_timestamp ON scheduled_jobs;
CREATE TRIGGER trg_update_scheduled_jobs_timestamp 
BEFORE UPDATE ON scheduled_jobs
FOR EACH ROW 
EXECUTE FUNCTION update_timestamp();

-- ============================================================================
-- NOTES DE SÉCURITÉ & BEST PRACTICES
-- ============================================================================

/*
SÉCURITÉ - CHECKLIST COMPLÈTE :

1. AUTHENTIFICATION & SESSIONS:
   ✓ Utiliser bcrypt/argon2 (hashage des mots de passe)
   ✓ JWT tokens + refresh tokens
   ✓ OTP/2FA pour tous les utilisateurs critiques
   ✓ Sessions tracks (IP, user_agent, device)
   ✓ Revocation automatique après expiration

2. CHIFFREMENT:
   ✓ TLS 1.3+ en transit
   ✓ Chiffrement au repos pour: emails, phones, numéros de carte
   ✓ AWS KMS ou Google Cloud KMS pour key management
   ✓ Hachage SHA-256 pour file_hash

3. CONFORMITÉ DONNÉES (RGPD):
   ✓ Soft-delete via deleted_at
   ✓ Purge automatique après X ans
   ✓ Anonymisation des données archivées
   ✓ Audit trails de tous les accès sensibles

4. FRAUDE & SÉCURITÉ:
   ✓ suspicious_activity_log pour détection anomalies
   ✓ Contrôles cash par chauffeur
   ✓ Limites transactions jour/semaine
   ✓ Alertes sur montants anormaux
   ✓ Géolocalisation: vérifier distance réelle vs estimée

5. PAIEMENTS (PCI-DSS):
   ✓ JAMAIS stocker numéros de cartes en clair
   ✓ Utiliser tokens de paiement
   ✓ Réconciliation quotidienne
   ✓ Logs de tous les paiements

6. GÉOLOCALISATION:
   ✓ PostGIS geometry POINT en WGS84 (4326)
   ✓ Indices GIST pour perfs
   ✓ Crowdsourcing d'adresses
   ✓ Alertes routes suspectes

7. BACKUP & DR:
   ✓ Backups quotidiens, rétention 30-90 jours
   ✓ Replicas en lecture
   ✓ RTO < 1 heure, RPO < 15 min

8. MONITORING:
   ✓ Logs centralisés (ELK, Splunk, Datadog)
   ✓ Alertes sur erreurs > seuil
   ✓ Crash reporting (Sentry)
*/