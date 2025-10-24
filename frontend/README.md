# Video AI Platform - Frontend

Frontend Vue 3 moderne pour la plateforme de transcription vidéo basée sur l'IA.

## 🚀 Technologies

- **Vue 3** - Framework progressif JavaScript
- **Vite** - Build tool ultra-rapide avec HMR
- **TypeScript** - Type safety
- **Tailwind CSS** - Utility-first CSS framework
- **Pinia** - State management
- **Vue Router** - Routing avec guards
- **Axios** - HTTP client
- **Keycloak** - Authentication OAuth2/OIDC

## 📁 Structure du Projet

```
frontend/
├── src/
│   ├── assets/          # Images, CSS globaux
│   ├── components/      # Composants réutilisables
│   │   ├── NavBar.vue
│   │   └── Footer.vue
│   ├── views/           # Pages/Vues
│   │   ├── HomeView.vue
│   │   ├── LoginView.vue
│   │   ├── UploadView.vue
│   │   ├── ProjectsView.vue
│   │   ├── ProjectDetailView.vue
│   │   ├── AdminView.vue
│   │   ├── AdminDashboardView.vue
│   │   └── PerformanceView.vue
│   ├── stores/          # Pinia stores
│   │   ├── auth.ts
│   │   ├── projects.ts
│   │   └── config.ts
│   ├── services/        # Services API
│   │   ├── api.ts
│   │   ├── keycloak.ts
│   │   └── projects.ts
│   ├── router/          # Configuration routing
│   │   └── index.ts
│   ├── types/           # TypeScript types
│   │   └── index.ts
│   ├── App.vue          # Composant racine
│   └── main.ts          # Point d'entrée
├── Dockerfile           # Multi-stage build
├── nginx.conf           # Configuration nginx
├── vite.config.ts       # Configuration Vite
├── tailwind.config.js   # Configuration Tailwind
└── tsconfig.json        # Configuration TypeScript
```

## 🛠️ Installation

```bash
# Installer les dépendances
npm install

# Copier le fichier .env
cp .env.example .env

# Éditer .env avec vos valeurs
# VITE_API_URL=http://192.168.1.23:8080/api
# VITE_KEYCLOAK_URL=http://192.168.1.23:8180
```

## 💻 Développement

```bash
# Lancer le serveur de développement
npm run dev

# Application disponible sur: http://localhost:3001
```

Le serveur Vite inclut:
- ⚡ Hot Module Replacement (HMR)
- 🔄 Auto-reload
- 🎯 Proxy API vers le backend

## 🏗️ Build Production

```bash
# Build pour production
npm run build

# Preview du build
npm run preview
```

Les fichiers sont générés dans `dist/`.

## 🐳 Docker

### Build l'image

```bash
docker build -t videoai/frontend:latest .
```

### Run le container

```bash
docker run -d \
  -p 3001:80 \
  --name videoai-frontend \
  videoai/frontend:latest
```

### Multi-stage build

Le Dockerfile utilise un build multi-stage:
1. **Builder:** Node.js 22 Alpine - Compile l'application
2. **Production:** Nginx 1.27 Alpine - Serve les fichiers statiques

Taille finale: ~50 MB

## 📊 Fonctionnalités

### 🎬 Upload de Vidéos
- Drag & drop
- Barre de progression en temps réel
- Support multi-formats (MP4, MOV, AVI, MKV)
- Validation de taille (max 2GB)

### 📁 Gestion de Projets
- Liste avec filtres
- Statut en temps réel (polling automatique)
- Actions rapides (voir, supprimer)
- Indicateurs de performance (CPU/GPU)

### 🎥 Détail du Projet
- Lecteur vidéo HTML5
- Transcription avec timestamps cliquables
- Export (TXT, SRT, VTT)
- Métriques de traitement
- Indicateur de speedup

### ⚙️ Admin - Configuration
- Stratégie de routage (Local/Hybrid/GCP)
- Configuration GPU GCP
- Seuil de durée vidéo
- Sélection modèle Whisper
- Estimation des coûts en temps réel

### 📊 Admin - Dashboard
- Statistiques globales
- Répartition CPU/GPU
- Santé du système
- Activité récente
- Actions rapides

### 📈 Performance
- Comparaison CPU vs GPU
- Métriques de traitement
- Analyse des coûts
- Calcul d'efficacité

## 🔐 Authentification

L'application utilise Keycloak pour l'authentification OAuth2:

1. **Login**: Redirection vers Keycloak
2. **Token JWT**: Stocké et auto-refresh
3. **Guards**: Protection des routes sensibles
4. **Roles**: Admin vs User

## 🌐 Proxy API

Vite et Nginx sont configurés pour proxyer les requêtes API:

**Développement (Vite):**
```
/api/* → http://192.168.1.23:8080/api/*
```

**Production (Nginx):**
```
/api/* → http://projects-service:8080/api/*
```

## 🎨 Styling

### Tailwind CSS

Classes utilitaires personnalisées dans `src/assets/main.css`:

```css
.btn           /* Bouton de base */
.btn-primary   /* Bouton principal */
.btn-secondary /* Bouton secondaire */
.btn-danger    /* Bouton danger */
.card          /* Carte avec shadow */
.input         /* Input stylisé */
```

### Palette de Couleurs

```js
primary: {
  50: '#eff6ff',
  500: '#3b82f6',  // Bleu principal
  600: '#2563eb',
  700: '#1d4ed8'
}
```

## 📱 Responsive Design

- **Mobile-first:** Design optimisé mobile d'abord
- **Breakpoints Tailwind:**
  - `sm:` 640px
  - `md:` 768px
  - `lg:` 1024px
  - `xl:` 1280px

## 🔄 État et Stores

### Auth Store
```typescript
const authStore = useAuthStore()
authStore.isAuthenticated  // Boolean
authStore.user             // User object
authStore.isAdmin          // Boolean
authStore.login()          // Function
authStore.logout()         // Function
```

### Projects Store
```typescript
const projectsStore = useProjectsStore()
projectsStore.projects           // Project[]
projectsStore.fetchAll()         // Load projects
projectsStore.create()           // Create project
projectsStore.uploadVideo()      // Upload with progress
projectsStore.startPolling()     // Real-time updates
```

### Config Store
```typescript
const configStore = useConfigStore()
configStore.config               // SystemConfig
configStore.dashboardStats       // DashboardStats
configStore.fetchConfig()        // Load config
configStore.updateConfig()       // Save config
```

## 🧪 Tests

```bash
# TODO: Ajouter les tests
npm run test
```

## 📦 Déploiement

### Via Docker Compose

Le frontend est inclus dans `infrastructure/proxmox/docker-compose.proxmox.yml`:

```yaml
frontend:
  image: videoai/frontend:latest
  ports:
    - "3001:80"
  environment:
    VITE_API_URL: http://192.168.1.23:8080/api
```

### Accès

```
http://192.168.1.23:3001
```

## 🐛 Troubleshooting

### Problème: CORS errors
**Solution:** Vérifier la configuration proxy dans `vite.config.ts` et `nginx.conf`

### Problème: Keycloak redirect loop
**Solution:** Vérifier que l'URL Keycloak est accessible depuis le navigateur

### Problème: API 404
**Solution:** Vérifier que le backend est démarré et accessible

## 📝 License

MIT

## 👥 Contribution

Pull requests welcome!

## 🤖 Généré avec

Claude Code - AI-powered development assistant
