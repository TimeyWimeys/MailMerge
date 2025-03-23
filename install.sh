#!/bin/bash

#     _/      _/            _/  _/  _/      _/                                        
#    _/_/  _/_/    _/_/_/      _/  _/_/  _/_/    _/_/    _/  _/_/    _/_/_/    _/_/   
#   _/  _/  _/  _/    _/  _/  _/  _/  _/  _/  _/_/_/_/  _/_/      _/    _/  _/_/_/_/  
#  _/      _/  _/    _/  _/  _/  _/      _/  _/        _/        _/    _/  _/         
# _/      _/    _/_/_/  _/  _/  _/      _/    _/_/_/  _/          _/_/_/    _/_/_/    
#                                                                    _/               

## Welcome to the installer of MailMerge

# Default Configuration
GITHUB_REPO="https://github.com/TimeyWimeys/mailmerge.git"
TARGET_DIR="/var/www/mailmerge"
MAILMERGE_USER="mailmerge"
MAILMERGE_GROUP="mailmerge"
NGINX_CONFIG="/etc/nginx/sites-available/mailmerge.conf"
LISTEN_PORT="5487"
SERVER_IP=$(ip route get 1.1.1.1 | awk '{print $7}')

# Ask user to confirm or change default values
echo "Current configuration:"
echo "MAILMERGE_USER: $MAILMERGE_USER"
echo "MAILMERGE_GROUP: $MAILMERGE_GROUP"
echo "NGINX_CONFIG: $NGINX_CONFIG"
echo "LISTEN_PORT: $LISTEN_PORT"
echo "SERVER_IP: $SERVER_IP"

# Function to prompt user for a new value
function prompt_for_value() {
    local var_name=$1
    local default_value=$2
    read -r -p "Do you want to change the $var_name? (y/n, default is n): " change
    if [[ "$change" == "y" || "$change" == "Y" ]]; then
        read -r -p "Enter new value for $var_name (default: $default_value): " new_value
        if [[ -n "$new_value" ]]; then
            eval "$var_name=\"$new_value\""
        else
            echo "Using default value for $var_name: $default_value"
            eval "$var_name=\"$default_value\""
        fi
    fi
}

# Prompt user for each configurable variable
prompt_for_value "MAILMERGE_USER" "$MAILMERGE_USER"
prompt_for_value "MAILMERGE_GROUP" "$MAILMERGE_GROUP"
prompt_for_value "NGINX_CONFIG" "$NGINX_CONFIG"
prompt_for_value "LISTEN_PORT" "$LISTEN_PORT"

# Create system user and group if not present
if ! id "$MAILMERGE_USER" &>/dev/null; then
    echo "Creating user and group..."
    groupadd --system $MAILMERGE_GROUP
    useradd --system --gid $MAILMERGE_GROUP --no-create-home --shell /usr/sbin/nologin $MAILMERGE_USER
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
chown -R $MAILMERGE_USER:$MAILMERGE_GROUP $TARGET_DIR
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

    try_files \$uri \$uri/ /index.php?\$args;
    index index.html index.php

    access_log /var/log/nginx/mailmerge_access.log;
    error_log /var/log/nginx/mailmerge_error.log;

    location / {
        try_files \$uri \$uri/ = 404;
    }

    location ~ \.php$ {
        fastcgi_pass unix:$PHP_SOCKET;
        fastcgi_index index.php;
        include fastcgi_params;
    }

}
EOL

# Enable site by creating symlink
if [ ! -L /etc/nginx/sites-enabled/mailmerge.conf ]; then
    echo "Enabling site..."
    ln -s $NGINX_CONFIG /etc/nginx/sites-enabled/mailmerge.conf
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
