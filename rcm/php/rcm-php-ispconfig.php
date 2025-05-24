#!/usr/bin/php
<?php
$ispconfig_remote_user_root = getenv('ISPCONFIG_REMOTE_USER_ROOT');
$ispconfig_remote_user_root or $ispconfig_remote_user_root = 'root';
define('ISPCONFIG_REMOTE_USER_ROOT', $ispconfig_remote_user_root);
$ispconfig_fqdn_localhost = getenv('ISPCONFIG_FQDN_LOCALHOST');
$ispconfig_fqdn_localhost or $ispconfig_fqdn_localhost = 'ispconfig.localhost';
define('ISPCONFIG_FQDN_LOCALHOST', $ispconfig_fqdn_localhost);
// The builtin function die() is not write error to stderr, we create
// alternative function named _die().
function _die($string='', $code = 1) {
    fwrite(STDERR, $string.PHP_EOL);
    exit($code);
}
function printVersion() {
    echo '0.9.22';
}
// Clone value.
$arguments_count = $argc;
$arguments_value = $argv;

array_shift($arguments_value); // Remove full path of script.
$arguments_count--;

// Read options for global.
$reset = false;
foreach ($arguments_value as $key => $value) {
    $shift = false;
    switch ($value) {
        case '--version':
            $shift = true;
            $version = true;
            break;
        case '--help':
            $shift = true;
            $help = true;
            break;
        default:
            if (preg_match('/^--/', $value)) {
                $shift = true;
            }
            else {
                // end options first operand.
                break 2;
            }
            break;
    }
    if ($shift) {
        unset($arguments_value[$key]);
        $arguments_count--;
        $reset = true;
    }
}
if ($reset) {
    array_values($arguments_value);
}

# Help and Version.
if (isset($version)) {
    printVersion(); echo PHP_EOL; exit(0);
}
if (isset($help)) {
    // Todo.
    exit(0);
}

// Read operand as a command.
$arguments_count > 0 or _die('Command required.');
$command = array_shift($arguments_value);
$arguments_count--;

// Read options for each command and prepare variables.
$soap_method = null;
$function = null;
$empty_array_is_false = false;
$quiet = false;
$path = null;
switch ($command) {
    case 'echo':
        $path = array_shift($arguments_value);
        $arguments_count--;
        $stdin = '';
        while (FALSE !== ($line = fgets(STDIN))) {
           $stdin .= $line;
        }
        // $debugname = 'stdin'; $debugvariable = '|||wakwaw|||'; if (array_key_exists($debugname, get_defined_vars())) { $debugvariable = $$debugname; } elseif (isset($this) && property_exists($this, $debugname)){ $debugvariable = $this->{$debugname}; $debugname = '$this->' . $debugname; } if ($debugvariable !== '|||wakwaw|||') {        echo "\r\n<pre>" . basename(__FILE__ ). ":" . __LINE__ . " (Time: " . date('c') . ", Direktori: " . dirname(__FILE__) . ")\r\n". 'var_dump(' . $debugname . '): '; var_dump($debugvariable); echo "</pre>\r\n"; }

        $input = unserialize($stdin);
        break;

    case 'soap':
        $reset = false;
        foreach ($arguments_value as $key => $value) {
            $shift = false;
            switch ($value) {
                case '--empty-array-is-false':
                    $shift = true;
                    $empty_array_is_false = true;
                    break;
                case '--quiet':
                    $shift = true;
                    $quiet = true;
                    break;
                default:
                    if (preg_match('/^--/', $value)) {
                        $shift = true;
                    }
                    else {
                        // end options first operand.
                        break 2;
                    }
                    break;
            }
            if ($shift) {
                unset($arguments_value[$key]);
                $arguments_count--;
                $reset = true;
            }
        }
        if ($reset) {
            array_values($arguments_value);
        }
        $arguments_count > 0 or _die('Method required.');
        $soap_method = array_shift($arguments_value);
        $arguments_count--;
        break;
}

// Execute command php.
switch ($command) {
    case 'echo':
        if ($path === null) {
            echo $input;
        }
        else if (preg_match('/^\[(.*)\]/', $path, $matches)) {
            $parents = explode('][', $matches[1]);
            // Clone.
            $array = $input;
            $ref =& $array;
            foreach ($parents as $parent) {
                if (is_array($ref) && (isset($ref[$parent]) || array_key_exists($parent, $ref))) {
                    $ref =& $ref[$parent];
                }
                else {
                    _die('Path invalid.');
                }
            }
            $key_exists = TRUE;
            echo $ref;
        }
        else {
            _die('Path is not valid.');
        }
        break;
}

// Prepare command soap.
switch ($soap_method) {
    case 'mail_domain':
        // Declare variable $app.
        $output = shell_exec('id -u ispconfig');
        $eid = rtrim($output);
        $user = posix_getpwuid($eid);
        $home = $user['dir'];
        chdir($home.'/interface/web');
        require_once '../lib/config.inc.php';
        require_once '../lib/app.inc.php';
        // The variable $app is ready.
        break;
    case 'login':
    case 'mail_alias_add':
    case 'mail_alias_get':
    case 'mail_user_add':
    case 'mail_user_get':
    case 'mail_domain_add':
    case 'mail_domain_get_by_domain':
    case 'client_get_by_username':
        // Declare variable $username, $password, $options.
        $path = '/usr/local/share/ispconfig/credential/remote/'.ISPCONFIG_REMOTE_USER_ROOT;
        if (!file_exists($path)) {
            fwrite(STDERR, 'File not found: '.$path.PHP_EOL);
            exit(1);
        }
        preg_match_all('/(.*)=(.*)/', file_get_contents($path), $matches);
        list($username, $password) = $matches[2];
        $options = [
            'location' => 'http://'.ISPCONFIG_FQDN_LOCALHOST.'/remote/index.php',
            'uri' => 'http://'.ISPCONFIG_FQDN_LOCALHOST.'/remote/',
            'trace' => 1,
            'exceptions' => 1,
        ];
        break;
    case 'client_add':
        // Declare variable $username, $password, $options.
        $path = '/usr/local/share/ispconfig/credential/remote/'.ISPCONFIG_REMOTE_USER_ROOT;
        if (!file_exists($path)) {
            _die('File not found: '.$path);
        }
        preg_match_all('/(.*)=(.*)/', file_get_contents($path), $matches);
        list($username, $password) = $matches[2];
        $options = [
            'location' => 'http://'.ISPCONFIG_FQDN_LOCALHOST.'/remote/index.php',
            'uri' => 'http://'.ISPCONFIG_FQDN_LOCALHOST.'/remote/',
            'trace' => 1,
            'exceptions' => 1,
        ];
        // Declare variable $app.
        $output = shell_exec('id -u ispconfig');
        $eid = rtrim($output);
        $user = posix_getpwuid($eid);
        $home = $user['dir'];
        chdir($home.'/interface/web');
        require_once '../lib/config.inc.php';
        require_once '../lib/app.inc.php';
        // The variable $app is ready.
        break;
}

// Execute command soap.
switch ($soap_method) {
    case 'mail_domain':
        $results = $app->db->queryAllRecords("SELECT domain FROM mail_domain");
        foreach ($results as $result) {
            echo $result['domain'].PHP_EOL;
        }
        break;
    case 'login':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
                $string = 'Logged successfull. Session ID: '.$session_id;
                fwrite(STDERR, $string.PHP_EOL);
            }
            if($client->logout($session_id)) {
                $string = 'Logged out.';
                fwrite(STDERR, $string.PHP_EOL);
            }
        } catch (SoapFault $e) {
            _die('SOAP Error: '.$e->getMessage());
        }
        break;
    case 'mail_domain_add':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            $argument = array_shift($arguments_value); // Harusnya value dari $client_id.
            $arguments_count--;
            if (is_numeric($argument)) {
                $client_id = (int) $argument;
            }
            else {
                $client_id = 0;
                array_unshift($arguments_value, $argument);
            }
            $params = [];
            while ($each = array_shift($arguments_value)) {
                // Wajib menggunakan multiline.
                // Ref: https://www.php.net/manual/en/reference.pcre.pattern.modifiers.php
                preg_match('/^--([a-z-0-9]+)=(.*)$/sm', $each, $matches_2);
                if (count($matches_2) == 3) {
                    list( , $key, $value) = $matches_2;
                    $key = str_replace('-','_',$key);
                    $params[$key] = $value;
                }
            }
            $record = $client->mail_domain_add($session_id, $client_id, $params);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            fwrite(STDERR, 'SOAP Error: '.$e->getMessage().PHP_EOL);
            exit(1);
        }
        break;
    case 'client_add':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            $argument = array_shift($arguments_value); // Harusnya value dari $reseller_id.
            $arguments_count--;
            if (is_numeric($argument)) {
                $reseller_id = (int) $argument;
            }
            else {
                $reseller_id = 0;
                array_unshift($arguments_value, $argument);
            }
            $params = [];
            while ($each = array_shift($arguments_value)) {
                preg_match('/^--(.*)=(.*)$/', $each, $matches_2);
                if (count($matches_2) == 3) {
                    list( , $key, $value) = $matches_2;
                    $key = str_replace('-','_',$key);
                    $params[$key] = $value;
                }
            }
            if (!array_key_exists('username', $params)) {
                throw new RuntimeException('Argument --username=* is required.');
            }
            if (!array_key_exists('password', $params)) {
                throw new RuntimeException('Argument --password=* is required.');
            }
            if (!array_key_exists('email', $params)) {
                throw new RuntimeException('Argument --email=* is required.');
            }
            if (!array_key_exists('contact_name', $params)) {
                $params['contact_name'] = 'Admin of '.$params['email'];
            }
            if (!array_key_exists('created_at', $params)) {
                $params['created_at'] = time();
            }
            $sql = "SELECT client_id FROM client ORDER BY client_id DESC LIMIT 1";
            $results = $app->db->queryOneRecord($sql);
            if (isset($results['client_id']) && is_numeric($results['client_id'])) {
                $client_id = (int) $results['client_id'];
            }
            else {
                $client_id = 0;
            }
            $default = [
                'company_name' => '',
                'customer_no' => 'C'.++$client_id,
                'vat_id' => '1',
                'street' => '',
                'zip' => '',
                'city' => '',
                'state' => '',
                'country' => 'ID',
                'telephone' => '',
                'mobile' => '',
                'fax' => '',
                'internet' => '',
                'icq' => '',
                'notes' => '',
                'default_mailserver' => 1,
                'limit_maildomain' => -1,
                'limit_mailbox' => -1,
                'limit_mailalias' => -1,
                'limit_mailaliasdomain' => -1,
                'limit_mailforward' => -1,
                'limit_mailcatchall' => -1,
                'limit_mailrouting' => 0,
                'limit_mail_wblist' => 0,
                'limit_mailfilter' => -1,
                'limit_fetchmail' => -1,
                'limit_mailquota' => -1,
                'limit_spamfilter_wblist' => 0,
                'limit_spamfilter_user' => 0,
                'limit_spamfilter_policy' => 1,
                'default_webserver' => 1,
                'limit_web_ip' => '',
                'limit_web_domain' => -1,
                'limit_web_quota' => -1,
                'web_php_options' => 'no,fast-cgi,cgi,mod,suphp',
                'limit_web_subdomain' => -1,
                'limit_web_aliasdomain' => -1,
                'limit_ftp_user' => -1,
                'limit_shell_user' => 0,
                'ssh_chroot' => 'no,jailkit,ssh-chroot',
                'limit_webdav_user' => 0,
                'default_dnsserver' => 1,
                'limit_dns_zone' => -1,
                'limit_dns_slave_zone' => -1,
                'limit_dns_record' => -1,
                'default_dbserver' => 1,
                'limit_database' => -1,
                'limit_cron' => 0,
                'limit_cron_type' => 'url',
                'limit_cron_frequency' => 5,
                'limit_traffic_quota' => -1,
                'limit_client' => 0, // If this value is > 0, then the client is a reseller
                'parent_client_id' => 0,
                'language' => 'en',
                'usertheme' => 'default',
                'template_master' => 0,
                'template_additional' => '',
                'startmodule' => 'dashboard',
            ];
            $params += $default;
            $record = $client->client_add($session_id, $reseller_id, $params);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            _die('SOAP Error: '.$e->getMessage());
        } catch (Exception $e) {
            _die('Exception Error: '.$e->getMessage());
        }
        break;
    case 'client_get_by_username':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            $argument = array_shift($arguments_value); // Harusnya value dari $username.
            $arguments_count--;
            if (!$argument) {
                throw new RuntimeException('Argument <username> is required.');
            }
            $username = $argument;
            $record = $client->client_get_by_username($session_id, $username);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            _die('SOAP Error: '.$e->getMessage());
        } catch (Exception $e) {
            _die('Exception Error: '.$e->getMessage());
        }
        break;
    case 'mail_domain_get_by_domain':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            $argument = array_shift($arguments_value); // Harusnya value dari $domain.
            $arguments_count--;
            if (!$argument) {
                throw new RuntimeException('Argument <domain> is required.');
            }
            $domain = $argument;
            $record = $client->mail_domain_get_by_domain($session_id, $domain);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            _die('SOAP Error: '.$e->getMessage());
        } catch (Exception $e) {
            _die('Exception Error: '.$e->getMessage());
        }
        break;
    case 'mail_user_get':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            $params = [];
            while ($each = array_shift($arguments_value)) {
                preg_match('/^--(.*)=(.*)$/', $each, $matches_2);
                if (count($matches_2) == 3) {
                    list( , $key, $value) = $matches_2;
                    $key = str_replace('-','_',$key);
                    $params[$key] = $value;
                }
            }
            if (!array_key_exists('email', $params)) {
                throw new RuntimeException('Argument --email=* is required.');
            }
            $record = $client->mail_user_get($session_id, $params);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            _die('SOAP Error: '.$e->getMessage());
        } catch (Exception $e) {
            _die('Exception Error: '.$e->getMessage());
        }
        break;
    case 'mail_user_add':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            $argument = array_shift($arguments_value); // Harusnya value dari $client_id.
            $arguments_count--;
            if (is_numeric($argument)) {
                $client_id = (int) $argument;
            }
            else {
                $client_id = 0;
                array_unshift($arguments_value, $argument);
            }
            $params = [];
            while ($each = array_shift($arguments_value)) {
                preg_match('/^--(.*)=(.*)$/', $each, $matches_2);
                if (count($matches_2) == 3) {
                    list( , $key, $value) = $matches_2;
                    $key = str_replace('-','_',$key);
                    $params[$key] = $value;
                }
            }
            if (!array_key_exists('email', $params)) {
                throw new RuntimeException('Argument --email=* is required.');
            }
            if (!array_key_exists('password', $params)) {
                throw new RuntimeException('Argument --password=* is required.');
            }
            if (!array_key_exists('login', $params)) {
                $params['login'] = $params['email'];
            }
            preg_match('/^(.*)@(.*)$/', $params['email'], $matches_3);
            if (!count($matches_3) == 3) {
                throw new InvalidArgumentException('Format --email=* is not valid.');
            }
            list(, $user, $host) = $matches_3;
            $default = [
                'server_id' => '1',
                'name' => $user,
                'uid' => '5000',
                'gid' => '5000',
                'maildir' => "/var/vmail/$host/$user",
                'maildir_format' => 'maildir',
                'quota' => '0',
                'cc' => '',
                'forward_in_lda' => 'y',
                'sender_cc' => '',
                'homedir' => '/var/vmail',
                'autoresponder' => 'n',
                'autoresponder_start_date' => NULL,
                'autoresponder_end_date' => NULL,
                'autoresponder_subject' => '',
                'autoresponder_text' => '',
                'move_junk' => 'Y',
                'purge_trash_days' => 0,
                'purge_junk_days' => 0,
                'custom_mailfilter' => NULL,
                'postfix' => 'y',
                'greylisting' => 'n',
                'access' => 'y',
                'disableimap' => 'n',
                'disablepop3' => 'n',
                'disabledeliver' => 'n',
                'disablesmtp' => 'n',
                'disablesieve' => 'n',
                'disablesieve-filter' => 'n',
                'disablelda' => 'n',
                'disablelmtp' => 'n',
                'disabledoveadm' => 'n',
                'disablequota-status' => 'n',
                'disableindexer-worker' => 'n',
                'last_quota_notification' => NULL,
                'backup_interval' => 'none',
                'backup_copies' => '1',
            ];
            $params += $default;
            $record = $client->mail_user_add($session_id, $client_id, $params);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            _die('SOAP Error: '.$e->getMessage());
        } catch (Exception $e) {
            _die('Exception Error: '.$e->getMessage());
        }
        break;
    case 'mail_alias_get':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            $params = [];
            while ($each = array_shift($arguments_value)) {
                preg_match('/^--(.*)=(.*)$/', $each, $matches_2);
                if (count($matches_2) == 3) {
                    list( , $key, $value) = $matches_2;
                    $key = str_replace('-','_',$key);
                    $params[$key] = $value;
                }
            }
            if (!array_key_exists('source', $params)) {
                throw new RuntimeException('Argument --source=* is required.');
            }
            if (!array_key_exists('destination', $params)) {
                throw new RuntimeException('Argument --destination=* is required.');
            }
            $record = $client->mail_alias_get($session_id, $params);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            _die('SOAP Error: '.$e->getMessage());
        } catch (Exception $e) {
            _die('Exception Error: '.$e->getMessage());
        }
        break;
    case 'mail_alias_add':
        $client = new SoapClient(null, $options);
        try {
            if($session_id = $client->login($username, $password)) {
            }
            $argument = array_shift($arguments_value); // Harusnya value dari $client_id.
            $arguments_count--;
            if (is_numeric($argument)) {
                $client_id = (int) $argument;
            }
            else {
                $client_id = 0;
                array_unshift($arguments_value, $argument);
            }
            $params = [];
            while ($each = array_shift($arguments_value)) {
                preg_match('/^--(.*)=(.*)$/', $each, $matches_2);
                if (count($matches_2) == 3) {
                    list( , $key, $value) = $matches_2;
                    $key = str_replace('-','_',$key);
                    $params[$key] = $value;
                }
            }
            if (!array_key_exists('source', $params)) {
                throw new RuntimeException('Argument --source=* is required.');
            }
            if (!array_key_exists('destination', $params)) {
                throw new RuntimeException('Argument --destination=* is required.');
            }
            $default = [
                'server_id' => '1',
                'type' => 'alias',
                'active' => 'y',
            ];
            $params += $default;
            $record = $client->mail_alias_add($session_id, $client_id, $params);
            if($client->logout($session_id)) {
            }
        } catch (SoapFault $e) {
            _die('SOAP Error: '.$e->getMessage());
        } catch (Exception $e) {
            _die('Exception Error: '.$e->getMessage());
        }
        break;
}
if (isset($record)) {
    if ($empty_array_is_false) {
        if (is_array($record) && empty($record)) {
            _die('The record is not found.');
        }
    }
    if  (!$quiet) {
        echo serialize($record);
    }
}
