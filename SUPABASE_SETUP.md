# Connecter le backend des commandes FORMA

Le site utilise Supabase pour garder le stock et les commandes partagés entre visiteurs. La clé anon/publishable est publique; les politiques RLS du schéma protègent les commandes. **Ne mettez jamais une clé service_role ici.**

1. Créez un projet Supabase.
2. Ouvrez SQL Editor et exécutez tout le fichier [supabase/schema.sql](supabase/schema.sql).
3. Dans Authentication → Users, créez votre utilisateur administrateur (email + mot de passe). Ne publiez pas d’inscription publique.
4. Dans SQL Editor, remplacez l’adresse ci-dessous par l’email admin créé puis exécutez :

```sql
insert into public.admin_users(user_id,email)
select id,email from auth.users where email = 'YOUR_ADMIN_EMAIL'
on conflict (user_id) do nothing;
```

5. Dans Project Settings → API, copiez Project URL et la clé anon/publishable.
6. Remplissez `url` et `anonKey` dans [supabase-config.js](supabase-config.js), puis enregistrez ce fichier sur GitHub.

Ensuite, l’admin se connecte depuis le bouton **Admin**. Vous pourrez y régler le vrai prix, le stock, la disponibilité et le statut des commandes. Les prix du benchmark ne sont pas activés comme prix de vente: chaque produit est initialement indisponible avec stock zéro. Les commandes sont transmises par la fonction RPC qui vérifie et décrémente le stock dans une transaction.

Le site est hébergé en pages statiques; le formulaire autofill utilise les champs standards du navigateur. Le paiement en ligne n’est pas activé (les commandes sont enregistrées pour traitement manuel).
