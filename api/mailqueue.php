<?php
header('Content-Type: application/json');
$data = json_decode(file_get_contents('php://input'), true);
$id = $data['id'] ?? '';
$action = $data['action'] ?? '';

if (empty($id) || !in_array($action, ['retry', 'delete'])) {
    echo json_encode(['message' => 'Invalid mail queue action.']);
    exit;
}

// For demonstration, we just return a dummy success message.
// Replace this with your actual mail queue logic.
echo json_encode(['message' => 'Mail queue action "' . $action . '" executed for message ' . $id . '.']);

