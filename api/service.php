<?php
header('Content-Type: application/json');

// Get JSON input
$data = json_decode(file_get_contents('php://input'), true);
$service = $data['service'] ?? '';
$action  = $data['action'] ?? '';

// Allowed services and actions
$allowedServices = ['Postfix', 'Dovecot', 'SpamAssassin', 'ClamAV'];
$allowedActions  = ['restart', 'stop', 'install'];

if (!in_array($service, $allowedServices) || !in_array($action, $allowedActions)) {
    echo json_encode(['message' => 'Invalid service or action.']);
    exit;
}

// Prepare the command to execute
$command = '';
if ($action === 'install') {
    // Map service names to package names (adjust as needed)
    $packageMap = [
        'Postfix'      => 'postfix',
        'Dovecot'      => 'dovecot',
        'SpamAssassin' => 'spamassassin',
        'ClamAV'       => 'clamav'
    ];
    if (!isset($packageMap[$service])) {
        echo json_encode(['message' => 'Package mapping not found.']);
        exit;
    }
    // For installation, we use apt-get. This will likely require root privileges.
    $command = "apt-get install -y " . escapeshellarg($packageMap[$service]);
} else {
    // For restart and stop, use systemctl.
    switch ($action) {
        case 'restart':
            $command = "systemctl restart " . escapeshellarg(strtolower($service));
            break;
        case 'stop':
            $command = "systemctl stop " . escapeshellarg(strtolower($service));
            break;
    }
}

// Execute the command and capture output (again, be extremely cautious with this)
$output = shell_exec($command . " 2>&1");
echo json_encode([
    'message' => 'Command executed: ' . $command,
    'output'  => $output
]);

