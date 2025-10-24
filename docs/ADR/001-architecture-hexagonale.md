# ADR-001: Architecture Hexagonale pour les Microservices

**Statut** : Accepté
**Date** : 2025-01-15
**Auteurs** : Équipe Architecture
**Décideurs** : CTO, Lead Architect

## Contexte

Nous développons une plateforme de traitement vidéo IA avec plusieurs microservices (Projects, Media-Ingest, Transcription, etc.). Nous devons choisir un pattern architectural qui permette :

- **Maintenabilité** : Code facile à modifier et étendre
- **Testabilité** : Tests unitaires sans dépendances externes
- **Découplage** : Isolation de la logique métier
- **Évolutivité** : Changement de technologie sans refonte

## Décision

Nous adoptons **l'architecture hexagonale** (Ports & Adapters) pour tous les microservices critiques, particulièrement le service **Projects**.

### Structure

```
src/main/java/com/videoai/projects/
├── domain/                 # Cœur métier (pur Java)
│   ├── model/             # Aggregates, Entities, Value Objects
│   ├── event/             # Domain Events
│   ├── service/           # Domain Services
│   └── exception/         # Domain Exceptions
│
├── application/           # Use Cases
│   ├── usecase/           # Application Services
│   └── port/
│       ├── in/            # Driving Ports (API)
│       └── out/           # Driven Ports (SPI)
│
└── infrastructure/        # Adapters techniques
    └── adapter/
        ├── in/
        │   └── rest/      # REST Controllers
        └── out/
            ├── persistence/    # Database
            ├── event/          # Kafka
            └── temporal/       # Workflows
```

### Principes

1. **Domain Layer** : Pur Java, zéro dépendance framework
2. **Application Layer** : Orchestration use cases, validation
3. **Infrastructure Layer** : Implémentations techniques (Quarkus, Postgres, Kafka)

### Flux de données

```
HTTP Request
    ↓
REST Adapter (in)
    ↓
Use Case (application)
    ↓
Domain Model (domain)
    ↓
Repository Port (out)
    ↓
Persistence Adapter (out)
    ↓
PostgreSQL
```

## Alternatives Considérées

### 1. Layered Architecture (N-Tier)

**Avantages** :
- Simplicité
- Familiarité équipe

**Inconvénients** :
- Couplage fort (couches dépendent des couches inférieures)
- Logique métier dispersée
- Tests difficiles (dépendances DB)

**Rejet** : Maintenance difficile à long terme.

### 2. Clean Architecture (Uncle Bob)

**Avantages** :
- Séparation stricte
- Testabilité excellente

**Inconvénients** :
- Verbosité (nombreuses interfaces)
- Courbe apprentissage

**Similarité** : Très proche de l'hexagonale. **Rejet partiel** : Complexité excessive pour notre contexte.

### 3. CQRS + Event Sourcing

**Avantages** :
- Scalabilité read/write
- Audit complet

**Inconvénients** :
- Complexité élevée
- Eventual consistency

**Rejet** : Over-engineering pour MVP. Envisageable Phase 3.

## Conséquences

### Positives ✅

- **Testabilité** : Domain testé sans DB/Kafka
- **Isolation métier** : Logique protégée des changements techniques
- **Flexibilité** : Changement Postgres → MongoDB possible
- **Onboarding** : Structure claire pour nouveaux dev

### Négatives ⚠️

- **Verbosité** : Plus de fichiers/interfaces
- **Courbe apprentissage** : Équipe doit maîtriser DDD
- **Over-engineering initial** : Complexe pour features simples

### Risques

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Équipe rejette complexité | Moyen | Formation DDD (2j) |
| Trop d'abstractions | Faible | Revue archi hebdo |
| Performance (layers) | Faible | Profiling régulier |

## Mesures de Succès

- [ ] 100% domain code sans annotation framework
- [ ] Couverture tests domain > 90%
- [ ] Changement adapter sans toucher domain
- [ ] Onboarding dev < 1 semaine

## Implémentation

### Phase 1 (Semaine 1-2)
- Service Projects en hexagonal
- Formation équipe (atelier DDD)

### Phase 2 (Semaine 3-4)
- Autres services critiques (Media-Ingest)
- Exemples/templates

### Phase 3 (Mois 2)
- Refactoring services existants
- Documentation patterns

## Références

- [Hexagonal Architecture - Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture/)
- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [DDD - Eric Evans](https://www.domainlanguage.com/ddd/)
- [Quarkus Hexagonal Example](https://github.com/quarkusio/quarkus-quickstarts/tree/main/hexagonal-architecture)

## Révisions

- **2025-01-15** : Création initiale
- **2025-02-01** : Ajout feedback équipe (suite formation)
- **2025-03-15** : Validation après implémentation Projects service

---

**Approbation** :
✅ CTO - 2025-01-15
✅ Lead Architect - 2025-01-15
✅ Tech Lead Projects - 2025-01-16
