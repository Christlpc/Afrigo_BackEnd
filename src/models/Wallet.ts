import pool from '../config/database';
import { Wallet, WalletTransaction, TransactionType } from '../types/database';

export class WalletModel {
  static async findByUserId(userId: number): Promise<Wallet | null> {
    const query = 'SELECT * FROM wallet WHERE user_id = $1';
    const result = await pool.query(query, [userId]);
    return result.rows[0] || null;
  }

  static async getBalance(userId: number): Promise<number> {
    const wallet = await this.findByUserId(userId);
    return wallet ? parseFloat(wallet.balance.toString()) : 0;
  }

  static async credit(
    userId: number,
    amount: number,
    description?: string,
    referenceType?: string,
    referenceId?: number
  ): Promise<WalletTransaction> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Vérifier/créer le wallet
      let wallet = await this.findByUserId(userId);
      if (!wallet) {
        const createQuery = 'INSERT INTO wallet (user_id, balance) VALUES ($1, 0) RETURNING *';
        const createResult = await client.query(createQuery, [userId]);
        wallet = createResult.rows[0];
      }

      // Mettre à jour le solde
      const updateQuery = `
        UPDATE wallet
        SET balance = balance + $1,
            total_earned = total_earned + $1,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $2
        RETURNING *
      `;
      await client.query(updateQuery, [amount, userId]);

      // Créer la transaction
      const transactionQuery = `
        INSERT INTO wallet_transactions (
          wallet_id, transaction_type, amount, description,
          reference_type, reference_id, status
        )
        VALUES ($1, $2, $3, $4, $5, $6, 'completed')
        RETURNING *
      `;
      const transactionResult = await client.query(transactionQuery, [
        wallet.id,
        'credit',
        amount,
        description || 'Recharge de portefeuille',
        referenceType || null,
        referenceId || null,
      ]);

      await client.query('COMMIT');
      return transactionResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async debit(
    userId: number,
    amount: number,
    description?: string,
    referenceType?: string,
    referenceId?: number
  ): Promise<WalletTransaction> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const wallet = await this.findByUserId(userId);
      if (!wallet) {
        throw new Error('Portefeuille non trouvé');
      }

      const currentBalance = parseFloat(wallet.balance.toString());
      if (currentBalance < amount) {
        throw new Error('Solde insuffisant');
      }

      // Mettre à jour le solde
      const updateQuery = `
        UPDATE wallet
        SET balance = balance - $1,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $2
        RETURNING *
      `;
      await client.query(updateQuery, [amount, userId]);

      // Créer la transaction
      const transactionQuery = `
        INSERT INTO wallet_transactions (
          wallet_id, transaction_type, amount, description,
          reference_type, reference_id, status
        )
        VALUES ($1, $2, $3, $4, $5, $6, 'completed')
        RETURNING *
      `;
      const transactionResult = await client.query(transactionQuery, [
        wallet.id,
        'debit',
        amount,
        description || 'Paiement',
        referenceType || null,
        referenceId || null,
      ]);

      await client.query('COMMIT');
      return transactionResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async getTransactions(
    userId: number,
    limit: number = 50,
    offset: number = 0
  ): Promise<WalletTransaction[]> {
    const query = `
      SELECT wt.*
      FROM wallet_transactions wt
      INNER JOIN wallet w ON wt.wallet_id = w.id
      WHERE w.user_id = $1
      ORDER BY wt.created_at DESC
      LIMIT $2 OFFSET $3
    `;
    const result = await pool.query(query, [userId, limit, offset]);
    return result.rows;
  }
}

