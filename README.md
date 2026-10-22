# FORMA Optique — boutique lunettes & lentilles

Boutique statique en français, pensée pour le marché tunisien : montures optiques, lunettes de soleil, lentilles de couleur, lentilles correctrices et entretien des lentilles.

## Catalogue actuel

- **SKU27862** — monture optique vert translucide, **57 TND**. C'est la seule référence et le seul prix confirmés dans le stock reçu.
- Les autres fiches affichent des **repères de prix observés chez des vendeurs tunisiens**, et non des produits ou tarifs FORMA confirmés. Elles doivent être remplacées par vos références réelles avant de prendre des commandes.

Repères consultés le 22 octobre 2026 : montures entrée de gamme 55–120 TND ; lunettes solaires entrée de gamme 15–60 TND ; collections d'opticien de quelques centaines à plus de 2 000 TND ; lentilles colorées 90 TND la paire en promotion ou 120 TND la boîte de cinq paires ; lentilles Clarity 1 Day à partir de 160 TND ; solution multifonctions 360 ml autour de 30–35 TND. Les prix changent selon marque, format et promotion.

### Sources marché

- [Nyvara](https://www.nyvara.net/)
- [AZZABI Optic — lunettes de vue](https://azzabioptic.com/lunettes-de-vue/lunettes-de-vue-femme/page/2/)
- [AZZABI Optic — lunettes de soleil](https://azzabioptic.com/lunettes-de-soleil/lunettes-de-soleil-femme/)
- [Tun Shop — lunettes de soleil](https://tun-shop.tn/collections/lunettes-soleil)
- [Tunis Lenses — lentilles colorées](https://tunislenses.com/)
- [AZZABI Optic — lentilles de contact](https://azzabioptic.com/categorie-produit/lentilles-de-contact/)
- [B Pharma — solution pour lentilles 360 ml](https://www.bpharma.tn/produit/eye-care-pharma-souples-solution-pour-lentilles-360ml/)

## Fonctionnalités

- Catalogue filtrable par famille de produits.
- Essayage caméra en direct de la monture SKU27862.
- Galerie photo produit issue des vues reçues.
- Les cartes de prix marché renvoient vers leur source et sont identifiées comme non confirmées.
- L'essayage reste dans le navigateur et ne téléverse pas la vidéo.

## Lancer localement

Servir la racine du dépôt avec un serveur web statique et ouvrir en HTTPS, ou en localhost pour l'essai caméra. Par exemple :

```bash
python -m http.server 8000
```

Ouvrir `http://localhost:8000`. L'essayage charge MediaPipe Tasks Vision depuis un CDN et son modèle depuis Google, donc une connexion internet est nécessaire au démarrage du suivi.

## Publication GitHub Pages

Le dépôt publie `index.html` depuis la branche `main`. GitHub Actions construit et publie la version à chaque mise à jour.
