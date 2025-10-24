# 🚀 COMMENCEZ ICI - Video AI Platform

**Bienvenue dans votre projet Video AI Platform !**

Ce fichier vous guide pour démarrer en **moins de 5 minutes**.

---

## ⚡ Démarrage Express

### 1️⃣ Ouvrez un terminal et exécutez :

```batch
cd E:\devaiplat\video-ai-platform
infrastructure\scripts\start-dev.bat
```

⏱️ **Attendez 30 secondes** pendant que l'infrastructure démarre...

### 2️⃣ Vérifiez que tout fonctionne :

Ouvrez votre navigateur :
- http://localhost:9001 (MinIO - minioadmin/minioadmin)
- http://localhost:8180 (Keycloak - admin/admin)
- http://localhost:3000 (Grafana - admin/admin)

✅ **Si vous voyez ces interfaces, l'infrastructure est OK !**

### 3️⃣ Démarrez le service principal :

**Nouveau terminal :**
```batch
cd E:\devaiplat\video-ai-platform\services\projects
mvnw.cmd quarkus:dev
```

⏱️ **Attendez ~10 secondes** pour le message :
```
Quarkus started in 2.3s. Listening on: http://localhost:8080
```

### 4️⃣ Testez l'API :

Ouvrez : http://localhost:8080/swagger-ui

✅ **Vous devriez voir l'interface Swagger !**

---

## 📚 Documentation Importante

### Pour Démarrer
1. **[QUICKSTART.md](QUICKSTART.md)** ← Lisez ceci en premier !
2. **[INSTALLATION_SUCCESS.md](INSTALLATION_SUCCESS.md)** ← Guide complet

### Pour Développer
3. **[PROJECT_STATUS.md](PROJECT_STATUS.md)** ← État du projet
4. **[COMMANDS_CHEATSHEET.md](COMMANDS_CHEATSHEET.md)** ← Toutes les commandes
5. **[README.md](README.md)** ← Documentation complète

### Pour Comprendre
6. **[docs/ADR/001-architecture-hexagonale.md](docs/ADR/001-architecture-hexagonale.md)** ← Architecture
7. **[docs/security/SECURITY.md](docs/security/SECURITY.md)** ← Sécurité

---

## 🎯 Que Faire Ensuite ?

### Aujourd'hui (1h)

✅ Infrastructure démarrée
✅ Service Projects lancé

**Prochaine action :**
- [ ] Lire [QUICKSTART.md](QUICKSTART.md) (10 min)
- [ ] Configurer Keycloak (20 min)
- [ ] Tester les endpoints API (10 min)

### Cette Semaine

- [ ] Implémenter les Use Cases
- [ ] Créer les tests unitaires
- [ ] Implémenter le REST Controller
- [ ] Créer le Repository

### Mois Prochain

- [ ] Workflows Temporal
- [ ] Intégration Whisper
- [ ] Service NLP
- [ ] Frontend Angular

---

## 🆘 Problème ?

### L'infrastructure ne démarre pas

```batch
cd infrastructure\docker
docker-compose down -v
docker-compose up -d
```

### Le service ne compile pas

```batch
cd services\projects
mvnw.cmd clean install -DskipTests
```

### Port déjà utilisé

```batch
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

### Tout réinitialiser

```batch
cd infrastructure\docker
docker-compose down -v
docker system prune -a -f
start-dev.bat
```

---

## 📞 Besoin d'Aide ?

1. **Vérifiez** [COMMANDS_CHEATSHEET.md](COMMANDS_CHEATSHEET.md)
2. **Consultez** [QUICKSTART.md](QUICKSTART.md)
3. **Lisez** les logs : `docker-compose logs -f`

---

## ✅ Checklist Rapide

- [ ] Docker Desktop est démarré
- [ ] Java 21 installé (`java -version`)
- [ ] Maven fonctionne (`mvnw.cmd --version`)
- [ ] Infrastructure lancée (start-dev.bat)
- [ ] PostgreSQL accessible (port 5432)
- [ ] Keycloak accessible (http://localhost:8180)
- [ ] Service Projects lancé (quarkus:dev)
- [ ] Swagger UI accessible (http://localhost:8080/swagger-ui)

---

## 🎉 Tout Fonctionne ?

**Félicitations ! Vous êtes prêt à développer.**

👉 **Prochaine étape** : Lire [QUICKSTART.md](QUICKSTART.md) pour comprendre le projet.

---

**Bon développement ! 🚀**
