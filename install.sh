#!/bin/bash

# Configuration
GITHUB_REPO="https://github.com/TimeyWimeys/Mailer.git"
TARGET_DIR="/var/www/Mailer"
MAILER_USER="mailer"
MAILER_GROUP="mailer"
NGINX_CONFIG="/etc/nginx/sites-available/mailer.conf"
LISTEN_PORT="5487"
SERVER_IP=$(ip route get 1.1.1.1 | awk '{print $7}')

# Create system user and group if not present
if ! id "$MAILER_USER" &>/dev/null; then
    echo "Creating user and group..."
    groupadd --system $MAILER_GROUP
    useradd --system --gid $MAILER_GROUP --no-create-home --shell /usr/sbin/nologin $MAILER_USER
fi

# Clone or update GitHub repo
if [ -d "$TARGET_DIR/.git" ]; then
    echo "Updating existing repo..."
    cd $TARGET_DIR && git pull
else
    echo "Cloning repository..."
    git clone $GITHUB_REPO $TARGET_DIR
fi

# Set permissions
chown -R $MAILER_USER:$MAILER_GROUP $TARGET_DIR
chmod -R 750 $TARGET_DIR

# Detect installed PHP version
PHP_SOCKET=$(find /var/run/php/ -name "php*-fpm.pid" | sort | head -n 1)
if [ -z "$PHP_SOCKET" ]; then
    echo "No PHP-FPM socket found! Is PHP installed?"
    exit 1
fi

echo "Detected PHP socket: $PHP_SOCKET"

# Write the nginx config file
echo "Creating nginx config at $NGINX_CONFIG..."
cat > "$NGINX_CONFIG" <<EOL
server {
    listen $LISTEN_PORT;
    server_name $SERVER_IP;

    root $TARGET_DIR;
    include /etc/nginx/global_settings;

    try_files $uri $uri/ /index.php?$args;
    index index.html index.php

    access_log /var/log/nginx/mailer_access.log;
    error_log /var/log/nginx/mailer_error.log;

    location / {
        try_files \$uri \$uri/ = 404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCKET;
    }
}
EOL

# Enable site by creating symlink
if [ ! -L /etc/nginx/sites-enabled/mailer.conf ]; then
    echo "Enabling site..."
    ln -s $NGINX_CONFIG /etc/nginx/sites-enabled/mailer.conf
fi

# Test and restart nginx
nginx -t && systemctl restart nginx

# Configure firewall
echo "Configuring firewall rules..."

# UFW
if command -v ufw &>/dev/null; then
    echo "Adding port $LISTEN_PORT to UFW..."
    ufw allow $LISTEN_PORT
fi

# Firewalld
if systemctl is-active --quiet firewalld; then
    echo "Adding port $LISTEN_PORT to firewalld..."
    firewall-cmd --permanent --add-port=$LISTEN_PORT/tcp
    firewall-cmd --reload
fi

# iptables
if command -v iptables &>/dev/null; then
    echo "Adding port $LISTEN_PORT to iptables..."
    iptables -I INPUT -p tcp --dport $LISTEN_PORT -j ACCEPT
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
fi

echo "Setup completed successfully."
