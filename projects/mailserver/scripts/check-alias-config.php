<?php

declare(strict_types=1);

$path = $argv[1] ?? __DIR__ . '/../secrets/alias-accounts.php';

if (!is_file($path)) {
    fwrite(STDERR, "ERROR: Datei nicht gefunden: {$path}\n");
    exit(1);
}

$data = include $path;

$masterPasswordPath = __DIR__ . '/../secrets/alias-master-password.txt';

if (!is_array($data)) {
    fwrite(STDERR, "ERROR: Datei muss ein PHP-Array zurueckgeben.\n");
    exit(1);
}

if (!is_file($masterPasswordPath)) {
    fwrite(STDERR, "ERROR: Master-Passwort-Datei fehlt: {$masterPasswordPath}\n");
    exit(1);
}

$masterPassword = file_get_contents($masterPasswordPath);
if ($masterPassword === false || rtrim($masterPassword, "\r\n") === '') {
    fwrite(STDERR, "ERROR: Master-Passwort-Datei ist leer oder unlesbar.\n");
    exit(1);
}

$errors = [];

foreach ($data as $mailbox => $account) {
    if (!is_string($mailbox) || !preg_match('/^[^@\s]+@cooolinho\.de$/i', $mailbox)) {
        $errors[] = "Ungueltiger Mailbox-Key: {$mailbox}";
        continue;
    }

    if (!is_array($account)) {
        $errors[] = "Eintrag fuer {$mailbox} muss ein Array sein.";
        continue;
    }

    foreach (['mailbox_password'] as $requiredKey) {
        if (!array_key_exists($requiredKey, $account) || (string) $account[$requiredKey] === '') {
            $errors[] = "{$mailbox}: {$requiredKey} fehlt oder ist leer.";
        }
    }

    if (isset($account['mailbox_user']) && (string) $account['mailbox_user'] === '') {
        $errors[] = "{$mailbox}: mailbox_user ist leer (optional, aber falls gesetzt nicht leer).";
    }
}

if ($errors !== []) {
    fwrite(STDERR, "Alias-Config FEHLER:\n");
    foreach ($errors as $error) {
        fwrite(STDERR, "- {$error}\n");
    }
    exit(2);
}

echo "Alias-Config OK. Accounts: " . count($data) . "\n";

