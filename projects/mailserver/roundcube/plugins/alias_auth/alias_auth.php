<?php

class alias_auth extends rcube_plugin
{
    public $task = 'login';

    private const ALLOWED_DOMAIN = 'cooolinho.de';
    private const CONFIG_PATH = '/run/secrets/alias-accounts.php';
    private const MASTER_PASSWORD_PATH = '/run/secrets/alias-master-password.txt';

    public function init()
    {
        $this->add_hook('authenticate', [$this, 'authenticate']);
    }

    public function authenticate(array $args): array
    {
        $rawUser = isset($args['user']) ? trim((string) $args['user']) : '';
        $inputPassword = isset($args['pass']) ? (string) $args['pass'] : '';

        $masterPassword = $this->loadMasterPassword();
        if ($masterPassword === '' || !hash_equals($masterPassword, $inputPassword)) {
            return $this->deny($args);
        }

        // Strict alias-only mode: only values like "mail@" are accepted.
        if (!$this->isAliasIdentifier($rawUser)) {
            return $this->deny($args);
        }

        $localPart = strtolower(substr($rawUser, 0, -1));
        $mailboxEmail = $localPart . '@' . self::ALLOWED_DOMAIN;
        $accounts = $this->loadAccounts();

        if (!isset($accounts[$mailboxEmail]) || !is_array($accounts[$mailboxEmail])) {
            return $this->deny($args);
        }

        $account = $accounts[$mailboxEmail];
        $mailboxPassword = isset($account['mailbox_password']) ? (string) $account['mailbox_password'] : '';

        if ($mailboxPassword === '') {
            return $this->deny($args);
        }

        $mailboxUser = isset($account['mailbox_user']) && $account['mailbox_user'] !== ''
            ? (string) $account['mailbox_user']
            : $mailboxEmail;

        $args['user'] = $mailboxUser;
        $args['pass'] = $mailboxPassword;

        return $args;
    }

    private function isAliasIdentifier(string $user): bool
    {
        if ($user === '' || substr($user, -1) !== '@') {
            return false;
        }

        // Prevent accidental full-email logins and limit to sane alias chars.
        if (strpos(substr($user, 0, -1), '@') !== false) {
            return false;
        }

        return preg_match('/^[a-z0-9._+-]+@$/i', $user) === 1;
    }

    private function loadAccounts(): array
    {
        if (!is_file(self::CONFIG_PATH) || !is_readable(self::CONFIG_PATH)) {
            return [];
        }

        $data = include self::CONFIG_PATH;

        if (!is_array($data)) {
            return [];
        }

        return $data;
    }

    private function loadMasterPassword(): string
    {
        if (!is_file(self::MASTER_PASSWORD_PATH) || !is_readable(self::MASTER_PASSWORD_PATH)) {
            return '';
        }

        $content = file_get_contents(self::MASTER_PASSWORD_PATH);
        if ($content === false) {
            return '';
        }

        // Remove trailing newlines from text-file based secret.
        return rtrim($content, "\r\n");
    }

    private function deny(array $args): array
    {
        $args['abort'] = true;
        $args['valid'] = false;

        return $args;
    }
}

