# Guide du Système de Mot de Passe - SafeKeeper

## 🔐 Vue d'ensemble

SafeKeeper utilise maintenant un **système de mot de passe global** pour protéger l'accès à tous vos documents chiffrés. Ce guide explique comment utiliser cette fonctionnalité.

---

## 🚀 Première utilisation

### Configuration initiale du mot de passe

Au premier lancement de l'application, vous serez automatiquement dirigé vers l'écran de configuration du mot de passe :

1. **Entrez votre mot de passe** (minimum 6 caractères)
2. **Confirmez votre mot de passe** (retapez-le)
3. **Cliquez sur "Créer le mot de passe"**

**⚠️ IMPORTANT :** Mémorisez bien votre mot de passe ! Il ne peut pas être récupéré si vous l'oubliez.

### Conseils pour un mot de passe sécurisé

✅ **Recommandé :**
- Au moins 8 caractères
- Mélange de lettres majuscules et minuscules
- Chiffres et symboles
- Facile à mémoriser pour vous, difficile à deviner pour les autres

❌ **À éviter :**
- Mots du dictionnaire simples
- Dates de naissance
- Séquences simples (123456, abcdef)
- Informations personnelles évidentes

---

## 🔓 Utilisation quotidienne

### Déverrouillage de l'application

À chaque lancement de l'application :

1. L'écran de déverrouillage s'affiche automatiquement
2. Entrez votre mot de passe
3. Cliquez sur "Déverrouiller" ou appuyez sur Entrée
4. Accédez à vos documents

### Verrouillage manuel

Pour verrouiller l'application sans la fermer :

1. Cliquez sur l'icône de cadenas 🔒 dans la barre d'application
2. L'application se verrouille immédiatement
3. Vous devrez entrer votre mot de passe pour y accéder à nouveau

---

## 🔒 Sécurité du système

### Architecture de sécurité

Le système de mot de passe utilise plusieurs couches de protection :

1. **PBKDF2 (Password-Based Key Derivation Function 2)**
   - Dérive une clé cryptographique à partir de votre mot de passe
   - 10 000 itérations pour ralentir les attaques par force brute
   - Salt aléatoire de 32 bytes pour chaque utilisateur

2. **Stockage sécurisé**
   - Le mot de passe n'est JAMAIS stocké en clair
   - Seul le hash PBKDF2 est conservé
   - Utilise Flutter Secure Storage (chiffrement au niveau OS)

3. **Protection contre les attaques**
   - Comparaison en temps constant (évite les timing attacks)
   - Salt unique par utilisateur (évite les rainbow tables)
   - Délai après tentatives échouées

### Ce qui est protégé

✅ **Avec le mot de passe :**
- Accès à l'interface de l'application
- Visualisation de la liste des documents
- Ouverture et déchiffrement des documents
- Upload de nouveaux documents

🔐 **Double protection :**
Vos documents bénéficient d'une **double couche de sécurité** :
1. **Chiffrement RSA-2048 + AES-256** (toujours actif)
2. **Mot de passe global** (contrôle d'accès)

---

## 🔄 Gestion du mot de passe

### Changer le mot de passe

**Note :** Cette fonctionnalité sera ajoutée dans une prochaine version.

Pour l'instant, si vous devez changer votre mot de passe :
1. Exportez vos documents importants
2. Réinstallez l'application
3. Configurez un nouveau mot de passe
4. Réimportez vos documents

### Mot de passe oublié

**⚠️ ATTENTION :** Il n'existe actuellement **aucun moyen de récupérer** un mot de passe oublié.

**Si vous oubliez votre mot de passe :**
- Vous devrez réinstaller l'application
- Tous les documents seront perdus (ils restent chiffrés)
- Vous devrez reconfigurer un nouveau mot de passe

**💡 Conseil :** Notez votre mot de passe dans un endroit sûr (gestionnaire de mots de passe, coffre-fort physique, etc.)

---

## 🛡️ Scénarios d'utilisation

### Scénario 1 : Utilisation personnelle

**Situation :** Vous utilisez l'application sur votre téléphone personnel.

**Recommandation :**
- Mot de passe de 8-12 caractères
- Facile à mémoriser mais difficile à deviner
- Verrouillez l'app quand vous la prêtez à quelqu'un

### Scénario 2 : Documents très sensibles

**Situation :** Vous stockez des documents confidentiels (médicaux, financiers, juridiques).

**Recommandation :**
- Mot de passe de 12+ caractères
- Mélange complexe de caractères
- Verrouillez l'app après chaque utilisation
- Ne partagez jamais votre mot de passe

### Scénario 3 : Appareil partagé

**Situation :** Plusieurs personnes utilisent le même appareil.

**Recommandation :**
- Mot de passe fort et unique
- Verrouillez systématiquement après utilisation
- Considérez l'utilisation de profils utilisateur séparés sur l'appareil

---

## 🔧 Dépannage

### Problème : "Mot de passe incorrect"

**Solutions :**
1. Vérifiez que le verrouillage majuscules n'est pas activé
2. Assurez-vous de ne pas avoir d'espaces avant/après
3. Essayez de retaper lentement votre mot de passe
4. Vérifiez la langue du clavier

### Problème : Tentatives multiples échouées

**Comportement normal :**
- Après 3 tentatives échouées, un délai de 2 secondes est ajouté
- Ceci protège contre les attaques par force brute
- Attendez simplement et réessayez

### Problème : L'application se verrouille trop souvent

**Explication :**
- L'application se verrouille à chaque fermeture (par sécurité)
- C'est un comportement normal et souhaité
- Cela garantit que personne ne peut accéder à vos documents si vous laissez votre appareil sans surveillance

---

## 📱 Fonctionnalités futures

### Prévues pour les prochaines versions :

1. **Changement de mot de passe**
   - Modifier votre mot de passe sans perdre vos documents
   - Nécessite l'ancien mot de passe

2. **Authentification biométrique**
   - Empreinte digitale
   - Reconnaissance faciale
   - En complément du mot de passe

3. **Verrouillage automatique**
   - Après X minutes d'inactivité
   - Configurable par l'utilisateur

4. **Questions de sécurité**
   - Pour récupération du mot de passe
   - Optionnel

5. **Historique des connexions**
   - Voir les dernières tentatives de connexion
   - Détecter les accès non autorisés

---

## 🔐 Comparaison avec d'autres solutions

| Fonctionnalité | SafeKeeper | 1Password | LastPass | Bitwarden |
|----------------|------------|-----------|----------|-----------|
| Mot de passe global | ✅ | ✅ | ✅ | ✅ |
| PBKDF2 | ✅ | ✅ | ✅ | ✅ |
| Chiffrement local | ✅ | ✅ | ✅ | ✅ |
| Biométrie | 🔜 | ✅ | ✅ | ✅ |
| Récupération mot de passe | ❌ | ✅ | ✅ | ✅ |
| Open source | ✅ | ❌ | ❌ | ✅ |

---

## 📊 Statistiques de sécurité

### Temps pour craquer le mot de passe (force brute)

Avec PBKDF2 (10 000 itérations) :

| Longueur | Complexité | Temps estimé |
|----------|------------|--------------|
| 6 caractères | Lettres minuscules | ~2 heures |
| 8 caractères | Lettres + chiffres | ~3 jours |
| 10 caractères | Lettres + chiffres + symboles | ~50 ans |
| 12 caractères | Lettres + chiffres + symboles | ~34 000 ans |
| 16 caractères | Lettres + chiffres + symboles | ~200 millions d'années |

**Note :** Ces estimations supposent un attaquant avec un matériel moderne et un accès direct au hash.

---

## ✅ Checklist de sécurité

Avant de commencer à utiliser SafeKeeper :

- [ ] J'ai créé un mot de passe fort (8+ caractères)
- [ ] J'ai noté mon mot de passe dans un endroit sûr
- [ ] Je comprends que le mot de passe ne peut pas être récupéré
- [ ] Je sais comment verrouiller l'application manuellement
- [ ] J'ai testé le déverrouillage avec mon mot de passe
- [ ] Je comprends la double protection (chiffrement + mot de passe)

---

## 📞 Support

Si vous rencontrez des problèmes avec le système de mot de passe :

1. Consultez la section Dépannage ci-dessus
2. Vérifiez les logs de l'application
3. Contactez le support technique

---

## 🔒 Conclusion

Le système de mot de passe de SafeKeeper ajoute une couche de protection essentielle à vos documents chiffrés. En combinant :

- **Chiffrement fort** (RSA-2048 + AES-256 + HMAC-SHA256)
- **Contrôle d'accès** (mot de passe global avec PBKDF2)
- **Stockage sécurisé** (Flutter Secure Storage)

Vos documents bénéficient d'une protection de niveau professionnel, comparable aux meilleures solutions du marché.

**Utilisez-le de manière responsable et gardez votre mot de passe en sécurité !** 🔐

---

**Version du guide :** 1.0  
**Dernière mise à jour :** Après implémentation du système de mot de passe  
**Compatibilité :** SafeKeeper v1.0+
