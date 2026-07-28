# alias_auth

Roundcube-Plugin fuer Alias-Only-Login.

## Verhalten

- Akzeptiert nur Login-Namen im Format `alias@` (z. B. `mail@`, `dev@`)
- Ergaenzt automatisch `@cooolinho.de`
- Prueft ein globales Master-Passwort aus `/run/secrets/alias-master-password.txt`
- Prueft nur, ob der Alias in `projects/mailserver/secrets/alias-accounts.php` vorhanden ist
- Nutzt danach intern die echten Mailbox-Zugangsdaten fuer IMAP/SMTP
- Kein Fallback auf normalen Roundcube-Login

## Konfigurationsdatei

Erwarteter Pfad im Container: `/run/secrets/alias-accounts.php`

Master-Passwort-Datei im Container: `/run/secrets/alias-master-password.txt`

Beispielstruktur:

```php
<?php

return [
    'mail@cooolinho.de' => [
        'mailbox_user' => 'mail@cooolinho.de',
        'mailbox_password' => 'HETZNER_MAILBOX_PASSWORT',
    ],
];
```

