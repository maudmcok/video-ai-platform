-- Script d'initialisation de la base de données

-- Création de la base keycloak si elle n'existe pas
SELECT 'CREATE DATABASE keycloak'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'keycloak')\gexec

-- Extensions nécessaires
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Commentaires
COMMENT ON DATABASE videoai IS 'Base de données principale de la plateforme Video AI';
