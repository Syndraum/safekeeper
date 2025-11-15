# Checklist de Test - Système de Mot de Passe SafeKeeper

## 🧪 Tests à effectuer

Utilisez cette checklist pour vérifier que le système de mot de passe fonctionne correctement.

---

## ✅ Phase 1 : Configuration initiale

### Test 1.1 : Premier lancement
- [ ] Lancer l'application pour la première fois
- [ ] **Résultat attendu :** L'écran de configuration du mot de passe s'affiche automatiquement
- [ ] **Vérification :** Titre "Configuration du mot de passe" visible

### Test 1.2 : Validation du formulaire
- [ ] Essayer de soumettre sans mot de passe
- [ ] **Résultat attendu :** Message d'erreur "Veuillez entrer un mot de passe"
- [ ] Entrer un mot de passe de 5 caractères
- [ ] **Résultat attendu :** Message d'erreur "Le mot de passe doit contenir au moins 6 caractères"

### Test 1.3 : Confirmation du mot de passe
- [ ] Entrer "password123" dans le premier champ
- [ ] Entrer "password456" dans le champ de confirmation
- [ ] Cliquer sur "Créer le mot de passe"
- [ ] **Résultat attendu :** Message d'erreur "Les mots de passe ne correspondent pas"

### Test 1.4 : Création réussie
- [ ] Entrer "password123" dans les deux champs
- [ ] Cliquer sur "Créer le mot de passe"
- [ ] **Résultat attendu :** 
  - Message de succès "Mot de passe configuré avec succès !"
  - Redirection vers la page d'accueil
  - Bouton de verrouillage visible dans l'AppBar

### Test 1.5 : Visibilité du mot de passe
- [ ] Cliquer sur l'icône œil dans le champ mot de passe
- [ ] **Résultat attendu :** Le mot de passe devient visible
- [ ] Cliquer à nouveau
- [ ] **Résultat attendu :** Le mot de passe est masqué

---

## ✅ Phase 2 : Déverrouillage

### Test 2.1 : Redémarrage de l'application
- [ ] Fermer complètement l'application
- [ ] Relancer l'application
- [ ] **Résultat attendu :** L'écran de déverrouillage s'affiche (pas l'écran de configuration)

### Test 2.2 : Mot de passe incorrect
- [ ] Entrer un mot de passe incorrect (ex: "wrongpassword")
- [ ] Cliquer sur "Déverrouiller"
- [ ] **Résultat attendu :** 
  - Message d'erreur "Mot de passe incorrect (1 tentative)"
  - Le champ est vidé
  - Reste sur l'écran de déverrouillage

### Test 2.3 : Tentatives multiples
- [ ] Entrer 3 mots de passe incorrects consécutivement
- [ ] **Résultat attendu :** 
  - Message "3 tentatives échouées"
  - Délai de 2 secondes avant de pouvoir réessayer
  - Indicateur visuel des tentatives échouées

### Test 2.4 : Mot de passe correct
- [ ] Entrer le mot de passe correct ("password123")
- [ ] Cliquer sur "Déverrouiller"
- [ ] **Résultat attendu :** 
  - Accès à la page d'accueil
  - Boutons "Uploader un document" et "Voir mes documents" visibles
  - Bouton de verrouillage dans l'AppBar

### Test 2.5 : Touche Entrée
- [ ] Sur l'écran de déverrouillage, entrer le mot de passe
- [ ] Appuyer sur la touche Entrée (au lieu de cliquer sur le bouton)
- [ ] **Résultat attendu :** L'application se déverrouille

---

## ✅ Phase 3 : Verrouillage manuel

### Test 3.1 : Verrouillage depuis la page d'accueil
- [ ] Être sur la page d'accueil (déverrouillé)
- [ ] Cliquer sur l'icône de cadenas dans l'AppBar
- [ ] **Résultat attendu :** 
  - Retour à l'écran de déverrouillage
  - Doit entrer le mot de passe pour revenir

### Test 3.2 : Persistance du verrouillage
- [ ] Verrouiller l'application
- [ ] Fermer l'application
- [ ] Relancer l'application
- [ ] **Résultat attendu :** L'écran de déverrouillage s'affiche

---

## ✅ Phase 4 : Intégration avec les documents

### Test 4.1 : Upload de document après déverrouillage
- [ ] Déverrouiller l'application
- [ ] Cliquer sur "Uploader un document"
- [ ] Sélectionner un fichier ou prendre une photo
- [ ] **Résultat attendu :** 
  - Le document est uploadé et chiffré
  - Message de succès
  - Document visible dans la liste

### Test 4.2 : Consultation de document après déverrouillage
- [ ] Déverrouiller l'application
- [ ] Cliquer sur "Voir mes documents"
- [ ] Cliquer sur un document
- [ ] **Résultat attendu :** 
  - Le document est déchiffré et affiché
  - Pas de demande de mot de passe supplémentaire

### Test 4.3 : Accès refusé si verrouillé
- [ ] Verrouiller l'application
- [ ] Essayer d'accéder directement à `/list` (si possible)
- [ ] **Résultat attendu :** Redirection vers l'écran de déverrouillage

---

## ✅ Phase 5 : Sécurité

### Test 5.1 : Stockage sécurisé
- [ ] Configurer un mot de passe
- [ ] Vérifier le stockage Flutter Secure Storage
- [ ] **Résultat attendu :** 
  - Clés `password_hash`, `password_salt`, `is_password_set` présentes
  - Valeurs en base64 (pas en clair)

### Test 5.2 : PBKDF2 appliqué
- [ ] Configurer le mot de passe "test123"
- [ ] Vérifier le hash stocké
- [ ] **Résultat attendu :** 
  - Hash différent du mot de passe original
  - Longueur de 44 caractères (32 bytes en base64)

### Test 5.3 : Salt unique
- [ ] Réinitialiser l'application
- [ ] Configurer le même mot de passe "test123"
- [ ] Comparer les hash
- [ ] **Résultat attendu :** Hash différent (salt différent)

### Test 5.4 : Temps de vérification
- [ ] Mesurer le temps de vérification du mot de passe
- [ ] **Résultat attendu :** ~100-200ms (PBKDF2 avec 10k itérations)

---

## ✅ Phase 6 : Interface utilisateur

### Test 6.1 : Design de l'écran de configuration
- [ ] Vérifier l'icône de sécurité
- [ ] Vérifier les conseils de sécurité
- [ ] Vérifier les couleurs et le style
- [ ] **Résultat attendu :** Interface claire et professionnelle

### Test 6.2 : Design de l'écran de déverrouillage
- [ ] Vérifier le gradient de fond
- [ ] Vérifier l'icône de cadenas
- [ ] Vérifier la carte de saisie
- [ ] **Résultat attendu :** Interface moderne et sécurisée

### Test 6.3 : Messages d'erreur
- [ ] Vérifier tous les messages d'erreur
- [ ] **Résultat attendu :** Messages clairs et en français

### Test 6.4 : Responsive design
- [ ] Tester sur différentes tailles d'écran
- [ ] **Résultat attendu :** Interface adaptée à toutes les tailles

---

## ✅ Phase 7 : Cas limites

### Test 7.1 : Mot de passe avec caractères spéciaux
- [ ] Configurer un mot de passe avec `!@#$%^&*()`
- [ ] Déverrouiller avec ce mot de passe
- [ ] **Résultat attendu :** Fonctionne correctement

### Test 7.2 : Mot de passe avec espaces
- [ ] Essayer de configurer "pass word" (avec espace)
- [ ] **Résultat attendu :** Accepté (les espaces sont valides)

### Test 7.3 : Mot de passe très long
- [ ] Configurer un mot de passe de 50+ caractères
- [ ] Déverrouiller avec ce mot de passe
- [ ] **Résultat attendu :** Fonctionne correctement

### Test 7.4 : Copier-coller du mot de passe
- [ ] Copier un mot de passe depuis un gestionnaire
- [ ] Coller dans le champ
- [ ] **Résultat attendu :** Fonctionne correctement

---

## ✅ Phase 8 : Performance

### Test 8.1 : Temps de configuration
- [ ] Mesurer le temps de création du mot de passe
- [ ] **Résultat attendu :** < 500ms

### Test 8.2 : Temps de déverrouillage
- [ ] Mesurer le temps de vérification
- [ ] **Résultat attendu :** 100-200ms

### Test 8.3 : Impact sur le démarrage
- [ ] Mesurer le temps de démarrage de l'app
- [ ] **Résultat attendu :** +2-3 secondes maximum

---

## ✅ Phase 9 : Compatibilité

### Test 9.1 : Linux
- [ ] Tester sur Linux
- [ ] **Résultat attendu :** Fonctionne correctement

### Test 9.2 : Android (si disponible)
- [ ] Tester sur Android
- [ ] **Résultat attendu :** Fonctionne correctement

### Test 9.3 : iOS (si disponible)
- [ ] Tester sur iOS
- [ ] **Résultat attendu :** Fonctionne correctement

---

## ✅ Phase 10 : Documentation

### Test 10.1 : Guide utilisateur
- [ ] Lire `PASSWORD_SYSTEM_GUIDE.md`
- [ ] **Résultat attendu :** Instructions claires et complètes

### Test 10.2 : Documentation technique
- [ ] Lire `IMPLEMENTATION_SUMMARY.md`
- [ ] **Résultat attendu :** Architecture bien documentée

### Test 10.3 : Commentaires dans le code
- [ ] Vérifier les commentaires dans `auth_service.dart`
- [ ] **Résultat attendu :** Code bien commenté

---

## 📊 Résumé des tests

### Statistiques

- **Total de tests :** 40+
- **Tests critiques :** 15
- **Tests de sécurité :** 8
- **Tests UI/UX :** 10
- **Tests de performance :** 3

### Priorités

**P0 (Critique) :**
- Configuration initiale
- Déverrouillage avec mot de passe correct
- Verrouillage manuel
- Stockage sécurisé

**P1 (Important) :**
- Validation des entrées
- Messages d'erreur
- Tentatives multiples
- Intégration avec documents

**P2 (Nice to have) :**
- Design UI
- Performance
- Cas limites
- Documentation

---

## 🐛 Bugs connus

### À corriger

1. **Aucun bug connu actuellement**

### Améliorations futures

1. Ajouter la biométrie
2. Ajouter le changement de mot de passe dans l'UI
3. Ajouter le verrouillage automatique
4. Ajouter les questions de sécurité

---

## ✅ Validation finale

Une fois tous les tests effectués :

- [ ] Tous les tests P0 passent
- [ ] Au moins 80% des tests P1 passent
- [ ] Documentation à jour
- [ ] Aucun bug critique
- [ ] Performance acceptable
- [ ] UX satisfaisante

**Si tous les critères sont remplis :** ✅ **SYSTÈME VALIDÉ POUR PRODUCTION**

---

## 📝 Notes de test

Utilisez cet espace pour noter vos observations :

```
Date : _______________
Testeur : _______________
Plateforme : _______________

Observations :
- 
- 
- 

Bugs trouvés :
- 
- 
- 

Suggestions :
- 
- 
- 
```

---

**Version :** 1.0  
**Dernière mise à jour :** Après implémentation du système de mot de passe  
**Status :** 📋 Prêt pour les tests
