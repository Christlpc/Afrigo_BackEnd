#!/bin/bash
# Script de build pour Render
# Ce script est exécuté automatiquement si configuré dans Render

echo "🔨 Installation des dépendances..."
yarn install

echo "📦 Compilation TypeScript..."
yarn build

echo "✅ Build terminé avec succès!"

