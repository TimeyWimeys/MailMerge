<?php
$services = ['postfix', 'clamav-daemon', 'spamassassin', 'dovecot'];

$result = [];

foreach ($services as $service) {
    $serviceCheck = shell_exec("systemctl is-enabled $service 2>/dev/null");
    if (empty(trim($serviceCheck))) {
        $result[$service] = [
            'status' => 'not installed',
            'uptime' => 'N/A'
        ];
        continue;
    }

    $statusOutput = shell_exec("systemctl is-active $service 2>/dev/null");
    $status = trim($statusOutput);

    if ($status === 'active') {
        // Get uptime using systemctl show
        $activeSince = shell_exec("systemctl show -p ActiveEnterTimestamp $service 2>/dev/null");
        preg_match('/ActiveEnterTimestamp=(.*)/', $activeSince, $matches);

        if (isset($matches[1])) {
            $startTime = strtotime($matches[1]);
            $uptimeSeconds = time() - $startTime;
            $uptime = gmdate("j\ d H\h i\m", $uptimeSeconds);
        } else {
            $uptime = 'Unknown';
        }
    } else {
        $uptime = 'not running';
    }

    $result[$service] = [
        'status' => $status,
        'uptime' => $uptime
    ];
}

header('Content-Type: application/json');
echo json_encode($result);
