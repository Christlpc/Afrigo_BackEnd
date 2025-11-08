/**
 * Script d'initialisation de la base de données
 * Ce script crée automatiquement un wallet pour tous les utilisateurs clients existants
 */

import pool from '../config/database';
import { UserModel } from '../models/User';

async function initDatabase() {
  try {
    console.log('🔧 Initialisation de la base de données...');

    // Récupérer tous les utilisateurs clients sans wallet
    const query = `
      SELECT u.id, u.user_type
      FROM users u
      LEFT JOIN wallet w ON u.id = w.user_id
      WHERE w.id IS NULL AND u.user_type = 'client'
    `;

    const result = await pool.query(query);
    const clientsWithoutWallet = result.rows;

    console.log(`📊 ${clientsWithoutWallet.length} clients sans wallet trouvés`);

    // Créer un wallet pour chaque client
    for (const client of clientsWithoutWallet) {
      await UserModel.createWallet(client.id);
      await UserModel.createClientProfile(client.id);
      console.log(`✅ Wallet créé pour le client ${client.id}`);
    }

    console.log('✅ Initialisation terminée avec succès');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors de l\'initialisation:', error);
    process.exit(1);
  }
}

initDatabase();

