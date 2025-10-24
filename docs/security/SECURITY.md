# Documentation Sécurité - Video AI Platform

## Vue d'ensemble

Cette plateforme implémente une approche **Security by Design** avec des contrôles à plusieurs niveaux selon le principe de **Defense in Depth**.

## Analyse des Menaces (STRIDE)

| Menace | Vecteur | Impact | Mitigation | Priorité |
|--------|---------|--------|------------|----------|
| **Spoofing** | Usurpation identité JWT | Accès projets tiers | • OAuth2/OIDC (Keycloak)<br>• Validation signature JWT<br>• Token expiration 15min<br>• Refresh token rotation | **P0** |
| **Tampering** | Modification données en transit | Injection commandes FFmpeg | • TLS 1.3 obligatoire<br>• Validation schéma<br>• Sanitization FFmpeg args<br>• Checksum S3 | **P0** |
| **Repudiation** | Actions non auditées | Absence de traçabilité | • Logs structurés (user_id)<br>• Kafka durable<br>• Retention 90j | **P1** |
| **Information Disclosure** | Exposition secrets | Leak credentials | • Masking logs<br>• Vault<br>• Erreurs génériques<br>• Pas de stack traces prod | **P0** |
| **Denial of Service** | Upload massif | Saturation infra | • Rate limiting (100 req/min)<br>• File size limit (500MB)<br>• Quotas utilisateur<br>• Circuit breakers | **P0** |
| **Elevation of Privilege** | Bypass authz | Accès admin | • RBAC Keycloak<br>• Ownership validation<br>• Least privilege containers | **P0** |

## Contrôles de Sécurité

### 1. Authentification & Autorisation

#### OAuth2/OIDC (Keycloak)

```properties
# Configuration Quarkus
quarkus.oidc.auth-server-url=http://localhost:8180/realms/videoai
quarkus.oidc.client-id=projects-service
quarkus.oidc.credentials.secret=${OIDC_CLIENT_SECRET}
quarkus.oidc.token.issuer=${quarkus.oidc.auth-server-url}
```

**Flux d'authentification :**

1. Utilisateur → Frontend → Keycloak (login)
2. Keycloak → Frontend (JWT + Refresh Token)
3. Frontend → API (Authorization: Bearer JWT)
4. API → Validation JWT (signature + expiration + claims)

#### RBAC (Role-Based Access Control)

**Rôles définis :**

- `USER` : Utilisateur standard (CRUD projets personnels)
- `PREMIUM` : Utilisateur premium (quotas étendus, features avancées)
- `ADMIN` : Administrateur (accès backoffice, modération)

**Enforcement :**

```java
@RolesAllowed("USER")
public Uni<Response> createProject(...) { }

@RolesAllowed("ADMIN")
public Uni<Response> listAllProjects(...) { }
```

### 2. Validation des Entrées

#### Bean Validation (JSR-380)

```java
public record CreateProjectRequest(
    @NotNull(message = "Type requis")
    ProjectType type,

    @Valid
    @NotNull
    ProjectConfig config,

    @Min(value = 10, message = "Durée minimale 10s")
    @Max(value = 7200, message = "Durée maximale 2h")
    Integer estimatedDuration
) {}
```

#### Sanitization URLs

```java
// Whitelist S3 buckets autorisés
private static final Pattern S3_URL_PATTERN =
    Pattern.compile("^s3://(videoai-uploads|videoai-assets)/[a-zA-Z0-9-_/]+$");

if (!S3_URL_PATTERN.matcher(url).matches()) {
    throw new SecurityException("Invalid S3 URL");
}
```

#### Protection Injection FFmpeg

```java
// ❌ MAUVAIS : Concaténation de chaînes
String command = "ffmpeg -i " + userInput + " output.mp4";

// ✅ BON : ProcessBuilder avec arguments séparés
List<String> command = List.of(
    "/usr/bin/ffmpeg",
    "-i", sanitizedInput,
    "-c:v", "libx264",
    "output.mp4"
);
ProcessBuilder pb = new ProcessBuilder(command);
```

### 3. Gestion des Secrets

#### Développement

```bash
# .env (jamais commité)
DB_PASSWORD=dev_password
OIDC_CLIENT_SECRET=secret
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin
```

#### Production (Vault)

```bash
# Vault CLI
vault kv put secret/videoai/projects \
  db.password=xxx \
  oidc.client.secret=yyy \
  s3.access.key=zzz

# Quarkus config
quarkus.datasource.password=${vault:secret/videoai/projects#db.password}
```

#### Kubernetes (Sealed Secrets)

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: videoai-secrets
spec:
  encryptedData:
    db-password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...
```

### 4. Rate Limiting

#### API Gateway (Kong/Traefik)

```yaml
# Kong plugin
plugins:
  - name: rate-limiting
    config:
      minute: 100
      hour: 1000
      policy: local
```

#### Application Level (Quarkus)

```java
@RateLimit(100)  // 100 req/min
@Path("/api/v1/projects")
public class ProjectResource { }
```

### 5. Protection CSRF/XSS

#### CSRF (SameSite Cookies)

```properties
quarkus.http.auth.session.cookie-same-site=strict
```

#### XSS (Content Security Policy)

```
Content-Security-Policy: default-src 'self';
  script-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  connect-src 'self' wss:;
```

#### Headers Sécurité

```yaml
# Traefik middleware
headers:
  customResponseHeaders:
    X-Frame-Options: "DENY"
    X-Content-Type-Options: "nosniff"
    X-XSS-Protection: "1; mode=block"
    Strict-Transport-Security: "max-age=31536000"
```

### 6. Logs & Monitoring

#### Logs Structurés (JSON)

```json
{
  "timestamp": "2025-01-15T14:23:45.123Z",
  "level": "INFO",
  "service": "projects-service",
  "trace_id": "4bf92f3577b34da6",
  "user_id": "550e8400-e29b-41d4-a716",
  "action": "create_project",
  "status": "success"
}
```

**Données masquées :**
- Passwords
- Tokens
- Secrets
- Credit cards
- PII (emails partiels)

#### Alertes Sécurité

```yaml
# Prometheus AlertManager
- alert: HighFailedLogins
  expr: rate(http_requests_total{endpoint="/login",status="401"}[5m]) > 10
  annotations:
    summary: "Tentatives de connexion échouées élevées"

- alert: UnauthorizedAccess
  expr: rate(http_requests_total{status="403"}[5m]) > 5
  annotations:
    summary: "Tentatives d'accès non autorisées"
```

## Checklist OWASP Top 10 (2021)

### A01:2021 - Broken Access Control
- [x] Validation ownership dans domain logic
- [x] JWT validé par middleware
- [x] CORS configuré strictement
- [x] Signed URLs S3 (expiration 15min)
- [x] RBAC appliqué sur endpoints

### A02:2021 - Cryptographic Failures
- [x] TLS 1.3 mandatory
- [x] S3 SSE-KMS encryption
- [x] Secrets dans Vault
- [x] Passwords hashés (Argon2)
- [x] JWT signé HMAC-SHA256

### A03:2021 - Injection
- [x] ProcessBuilder (pas de shell)
- [x] Requêtes SQL paramétrées
- [x] Validation URLs (regex whitelist)
- [x] JSONB sanitized

### A04:2021 - Insecure Design
- [x] Threat modeling (STRIDE)
- [x] Least privilege
- [x] Defense in depth
- [x] Fail securely

### A05:2021 - Security Misconfiguration
- [x] Pas de credentials par défaut
- [x] Swagger désactivé en prod
- [x] Headers sécurité
- [x] Dépendances épinglées

### A06:2021 - Vulnerable Components
- [x] SBOM généré (CycloneDX)
- [x] Scan SCA (Snyk)
- [x] Renovate bot (auto-updates)

### A07:2021 - Authentication Failures
- [x] OAuth2/OIDC
- [x] MFA optionnel
- [x] Session stateless (JWT)
- [x] Rate limiting login

### A08:2021 - Software Integrity
- [x] Signed images (Cosign)
- [x] Checksums S3
- [x] Code signing (GPG)

### A09:2021 - Logging Failures
- [x] Logs structurés
- [x] Corrélation trace_id
- [x] Alertes anomalies
- [x] Retention 90j

### A10:2021 - SSRF
- [x] Whitelist domaines
- [x] Metadata endpoint bloqué
- [x] Network policies K8s

## Tests de Sécurité

### SAST (Static Analysis)

```bash
# Semgrep
semgrep --config=auto --json .

# SonarQube
mvn sonar:sonar
```

### SCA (Dependency Scanning)

```bash
# OWASP Dependency-Check
mvn dependency-check:check

# Snyk
snyk test
```

### DAST (Dynamic Analysis)

```bash
# OWASP ZAP
zap-baseline.py -t https://api.staging.example.com
```

### Secrets Scanning

```bash
# TruffleHog
trufflehog git file://. --json
```

### Container Scanning

```bash
# Trivy
trivy image videoai/projects:latest
```

## Incident Response

### Procédure en cas de breach

1. **Détection** : Alertes Prometheus/Grafana
2. **Confinement** : Isolation service compromis
3. **Investigation** : Analyse logs ELK
4. **Éradication** : Patch/rebuild
5. **Récupération** : Restore depuis backup
6. **Post-mortem** : ADR + amélioration

### Contacts

- **Security Team** : security@videoai.example.com
- **On-call** : +33 X XX XX XX XX
- **PGP Key** : https://keys.example.com/security.asc

## Conformité

### RGPD

- [x] Consentement explicite
- [x] Droit à l'oubli (DELETE /users/:id)
- [x] Portabilité données (export JSON)
- [x] Chiffrement at-rest & in-transit
- [x] Privacy by Design
- [x] DPO désigné

### SOC 2

- [ ] Audit annuel
- [ ] Pen-testing externe
- [ ] Certification

## Références

- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
