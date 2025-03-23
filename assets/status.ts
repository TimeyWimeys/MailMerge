interface ServiceStatus {
    status: string;
    uptime: string;
}

interface ServiceData {
    [serviceName: string]: ServiceStatus;
}

function updateServiceStatuses(): void {
    fetch('status.php')
        .then(response => response.json())
        .then((data: ServiceData) => {
            for (const service in data) {
                const row = document.getElementById(`${service}-row`);
                if (row) {
                    const statusCell = row.querySelector<HTMLElement>('.service-status');
                    const uptimeCell = row.querySelector<HTMLElement>('.service-uptime');

                    if (statusCell && uptimeCell) {
                        const statusInfo = data[service].status;
                        let badgeClass = 'badge-secondary';

                        if (statusInfo === 'active') {
                            badgeClass = 'badge-success';
                        } else if (statusInfo === 'inactive' || statusInfo === 'failed') {
                            badgeClass = 'badge-error';
                        } else if (statusInfo === 'not installed') {
                            badgeClass = 'badge-warning';
                        }

                        statusCell.innerHTML = `<span class="badge ${badgeClass}">${statusInfo}</span>`;
                        uptimeCell.textContent = data[service].uptime;
                    }
                }
            }
        })
        .catch(err => console.error('Error fetching service status:', err));
}

// Refresh every 30 seconds
setInterval(updateServiceStatuses, 30000);
window.onload = updateServiceStatuses;