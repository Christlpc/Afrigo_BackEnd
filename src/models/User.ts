import pool from '../config/database';
import { User, UserType, UserStatus } from '../types/database';
import bcrypt from 'bcrypt';

export class UserModel {
  static async create(
    email: string,
    phone: string,
    password: string,
    userType: UserType,
    firstName?: string,
    lastName?: string
  ): Promise<User> {
    const passwordHash = await bcrypt.hash(password, 10);
    const query = `
      INSERT INTO users (email, phone, password_hash, user_type, first_name, last_name, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'pending')
      RETURNING *
    `;
    const result = await pool.query(query, [
      email,
      phone,
      passwordHash,
      userType,
      firstName || null,
      lastName || null,
    ]);
    return result.rows[0];
  }

  static async findByEmail(email: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL';
    const result = await pool.query(query, [email]);
    return result.rows[0] || null;
  }

  static async findByPhone(phone: string): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE phone = $1 AND deleted_at IS NULL';
    const result = await pool.query(query, [phone]);
    return result.rows[0] || null;
  }

  static async findById(id: number): Promise<User | null> {
    const query = 'SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL';
    const result = await pool.query(query, [id]);
    return result.rows[0] || null;
  }

  static async verifyPassword(user: User, password: string): Promise<boolean> {
    return bcrypt.compare(password, user.password_hash);
  }

  static async updateStatus(
    id: number,
    status: UserStatus
  ): Promise<User> {
    const query = `
      UPDATE users 
      SET status = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING *
    `;
    const result = await pool.query(query, [status, id]);
    return result.rows[0];
  }

  static async createClientProfile(userId: number): Promise<void> {
    const query = `
      INSERT INTO client_profile (user_id)
      VALUES ($1)
      ON CONFLICT (user_id) DO NOTHING
    `;
    await pool.query(query, [userId]);
  }

  static async createWallet(userId: number): Promise<void> {
    const query = `
      INSERT INTO wallet (user_id, balance)
      VALUES ($1, 0)
      ON CONFLICT (user_id) DO NOTHING
    `;
    await pool.query(query, [userId]);
  }
}

