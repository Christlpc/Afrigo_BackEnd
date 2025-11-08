import pool from '../config/database';
import { Address } from '../types/database';

export class AddressModel {
  static async create(
    userId: number | null,
    fullAddress: string,
    latitude: number,
    longitude: number,
    addressLabel?: string,
    city?: string,
    district?: string,
    additionalInfo?: string
  ): Promise<Address> {
    const query = `
      INSERT INTO addresses (
        user_id, full_address, latitude, longitude, location,
        address_label, city, district, additional_info
      )
      VALUES (
        $1, $2, $3, $4, 
        ST_SetSRID(ST_MakePoint($4, $3), 4326),
        $5, $6, $7, $8
      )
      RETURNING *
    `;
    
    const result = await pool.query(query, [
      userId,
      fullAddress,
      latitude,
      longitude,
      addressLabel || null,
      city || null,
      district || null,
      additionalInfo || null,
    ]);
    
    return result.rows[0];
  }

  static async findById(id: number): Promise<Address | null> {
    const query = 'SELECT * FROM addresses WHERE id = $1';
    const result = await pool.query(query, [id]);
    return result.rows[0] || null;
  }

  static async findByUserId(userId: number): Promise<Address[]> {
    const query = 'SELECT * FROM addresses WHERE user_id = $1 ORDER BY created_at DESC';
    const result = await pool.query(query, [userId]);
    return result.rows;
  }

  static async updateFavorite(
    id: number,
    userId: number,
    isFavorite: boolean
  ): Promise<Address> {
    const query = `
      UPDATE addresses
      SET is_favorite = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2 AND user_id = $3
      RETURNING *
    `;
    const result = await pool.query(query, [isFavorite, id, userId]);
    return result.rows[0];
  }
}

