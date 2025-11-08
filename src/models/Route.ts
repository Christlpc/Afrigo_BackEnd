import pool from '../config/database';
import {
  Route,
  RouteType,
  RouteStatus,
  VipClass,
  PaymentMethod,
  PaymentStatus,
} from '../types/database';

export class RouteModel {
  static async create(
    clientId: number,
    pickupAddressId: number,
    dropoffAddressId: number,
    pickupLatitude: number,
    pickupLongitude: number,
    dropoffLatitude: number,
    dropoffLongitude: number,
    routeType: RouteType,
    vipClass?: VipClass,
    scheduledAt?: Date,
    thirdPartyOrder?: boolean,
    thirdPartyName?: string,
    thirdPartyPhone?: string,
    notes?: string
  ): Promise<Route> {
    const query = `
      INSERT INTO routes (
        client_id, pickup_address_id, dropoff_address_id,
        pickup_location, dropoff_location,
        route_type, vip_class, status,
        scheduled_at, third_party_order, third_party_name, third_party_phone, notes
      )
      VALUES (
        $1, $2, $3,
        ST_SetSRID(ST_MakePoint($4, $5), 4326),
        ST_SetSRID(ST_MakePoint($6, $7), 4326),
        $8, $9, 'pending',
        $10, $11, $12, $13, $14
      )
      RETURNING *
    `;

    const result = await pool.query(query, [
      clientId,
      pickupAddressId,
      dropoffAddressId,
      pickupLongitude,
      pickupLatitude,
      dropoffLongitude,
      dropoffLatitude,
      routeType,
      vipClass || null,
      scheduledAt || null,
      thirdPartyOrder || false,
      thirdPartyName || null,
      thirdPartyPhone || null,
      notes || null,
    ]);

    return result.rows[0];
  }

  static async findById(id: number): Promise<Route | null> {
    const query = `
      SELECT r.*, 
        pa.full_address as pickup_address,
        da.full_address as dropoff_address
      FROM routes r
      LEFT JOIN addresses pa ON r.pickup_address_id = pa.id
      LEFT JOIN addresses da ON r.dropoff_address_id = da.id
      WHERE r.id = $1
    `;
    const result = await pool.query(query, [id]);
    return result.rows[0] || null;
  }

  static async findByClientId(clientId: number): Promise<Route[]> {
    const query = `
      SELECT r.*, 
        pa.full_address as pickup_address,
        da.full_address as dropoff_address
      FROM routes r
      LEFT JOIN addresses pa ON r.pickup_address_id = pa.id
      LEFT JOIN addresses da ON r.dropoff_address_id = da.id
      WHERE r.client_id = $1
      ORDER BY r.created_at DESC
    `;
    const result = await pool.query(query, [clientId]);
    return result.rows;
  }

  static async updateStatus(
    id: number,
    status: RouteStatus,
    driverId?: number
  ): Promise<Route> {
    const updates: string[] = [];
    const values: any[] = [];

    updates.push('status = $' + (values.length + 1));
    values.push(status);

    if (driverId) {
      updates.push('driver_id = $' + (values.length + 1));
      values.push(driverId);
    }

    if (status === 'pickup') {
      updates.push('started_at = CURRENT_TIMESTAMP');
    }

    if (status === 'completed') {
      updates.push('completed_at = CURRENT_TIMESTAMP');
    }

    if (status === 'cancelled') {
      updates.push('cancelled_at = CURRENT_TIMESTAMP');
    }

    updates.push('updated_at = CURRENT_TIMESTAMP');

    const query = `
      UPDATE routes
      SET ${updates.join(', ')}
      WHERE id = $${values.length + 1}
      RETURNING *
    `;
    values.push(id);

    const result = await pool.query(query, values);
    return result.rows[0];
  }

  static async updateFare(
    id: number,
    baseFare: number,
    distanceFare: number,
    timeFare: number,
    totalFare: number,
    estimatedDistance?: number,
    estimatedDuration?: number,
    commissionRate: number = 15
  ): Promise<Route> {
    // Calculer la commission et les gains du chauffeur
    const commissionAmount = (totalFare * commissionRate) / 100;
    const driverEarnings = totalFare - commissionAmount;

    const query = `
      UPDATE routes
      SET base_fare = $1,
          distance_fare = $2,
          time_fare = $3,
          total_fare = $4,
          commission_amount = $5,
          commission_rate = $6,
          driver_earnings = $7,
          estimated_distance = COALESCE($8, estimated_distance),
          estimated_duration = COALESCE($9, estimated_duration),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $10
      RETURNING *
    `;
    const result = await pool.query(query, [
      baseFare,
      distanceFare,
      timeFare,
      totalFare,
      commissionAmount,
      commissionRate,
      driverEarnings,
      estimatedDistance || null,
      estimatedDuration || null,
      id,
    ]);
    return result.rows[0];
  }

  static async updatePayment(
    id: number,
    paymentMethod: PaymentMethod,
    paymentStatus: PaymentStatus
  ): Promise<Route> {
    const query = `
      UPDATE routes
      SET payment_method = $1,
          payment_status = $2,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $3
      RETURNING *
    `;
    const result = await pool.query(query, [paymentMethod, paymentStatus, id]);
    return result.rows[0];
  }

  static async findAvailableDrivers(
    routeType: RouteType,
    latitude: number,
    longitude: number,
    radiusKm: number = 5
  ): Promise<any[]> {
    const vehicleTypeMap: Record<RouteType, string> = {
      taxi: 'taxi',
      moto: 'moto',
      vip: 'vip',
      carpool: 'taxi',
    };

    const vehicleType = vehicleTypeMap[routeType];

    const query = `
      SELECT 
        dp.id,
        dp.user_id,
        u.first_name,
        u.last_name,
        u.phone,
        dp.vehicle_type,
        dp.vehicle_brand,
        dp.vehicle_model,
        dp.license_plate,
        dp.current_location,
        dp.average_rating,
        ST_Distance(
          dp.current_location::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography
        ) / 1000 AS distance_km
      FROM driver_profile dp
      INNER JOIN users u ON dp.user_id = u.id
      WHERE dp.online_status = true
        AND dp.vehicle_type = $3
        AND u.status = 'active'
        AND u.kyc_status = 'verified'
        AND ST_DWithin(
          dp.current_location::geography,
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
          $4 * 1000
        )
      ORDER BY distance_km ASC
      LIMIT 10
    `;

    const result = await pool.query(query, [
      longitude,
      latitude,
      vehicleType,
      radiusKm,
    ]);
    return result.rows;
  }
}

