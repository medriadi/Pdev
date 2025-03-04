#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Installing Database Systems..."

# Update package manager
update_pkg_manager

# Install MongoDB
install_mongodb() {
    if ! command_exists "mongod"; then
        curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
        update_pkg_manager
        install_package "mongodb-org"
        systemctl start mongod
        systemctl enable mongod
        
        # Install MongoDB Compass if GUI tools are enabled
        if [ "$(get_config_value INSTALL_GUI_TOOLS true)" = "true" ]; then
            wget https://downloads.mongodb.com/compass/mongodb-compass_1.40.4_amd64.deb
            dpkg -i mongodb-compass_1.40.4_amd64.deb
            rm mongodb-compass_1.40.4_amd64.deb
        fi
    fi
}

# Install PostgreSQL
install_postgresql() {
    install_package "postgresql"
    install_package "postgresql-contrib"
    systemctl start postgresql
    systemctl enable postgresql
    
    # Install pgAdmin if GUI tools are enabled
    if [ "$(get_config_value INSTALL_GUI_TOOLS true)" = "true" ]; then
        curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
        echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" | sudo tee /etc/apt/sources.list.d/pgadmin4.list
        update_pkg_manager
        install_package "pgadmin4-desktop"
    fi
}

# Install MySQL
install_mysql() {
    install_package "mysql-server"
    systemctl start mysql
    systemctl enable mysql
    
    # Install MySQL Workbench if GUI tools are enabled
    if [ "$(get_config_value INSTALL_GUI_TOOLS true)" = "true" ]; then
        install_package "mysql-workbench"
    fi
}

# Install Redis
install_redis() {
    install_package "redis-server"
    systemctl start redis-server
    systemctl enable redis-server
    
    # Install RedisInsight if GUI tools are enabled
    if [ "$(get_config_value INSTALL_GUI_TOOLS true)" = "true" ]; then
        wget https://download.redisinsight.redis.com/latest/RedisInsight-v2-linux-amd64.deb
        dpkg -i RedisInsight-v2-linux-amd64.deb
        rm RedisInsight-v2-linux-amd64.deb
    fi
}

# Install SQLite
install_sqlite() {
    install_package "sqlite3"
    install_package "libsqlite3-dev"
    
    # Install DB Browser for SQLite if GUI tools are enabled
    if [ "$(get_config_value INSTALL_GUI_TOOLS true)" = "true" ]; then
        install_package "sqlitebrowser"
    fi
}

# Install Elasticsearch
install_elasticsearch() {
    if ! command_exists "elasticsearch"; then
        wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
        update_pkg_manager
        install_package "elasticsearch"
        systemctl start elasticsearch
        systemctl enable elasticsearch
        
        # Install Kibana if GUI tools are enabled
        if [ "$(get_config_value INSTALL_GUI_TOOLS true)" = "true" ]; then
            install_package "kibana"
            systemctl start kibana
            systemctl enable kibana
        fi
    fi
}

# Install databases based on configuration
DEFAULT_DB=$(get_config_value "DEFAULT_DB" "postgresql")

# Always install the default database
case $DEFAULT_DB in
    "mongodb") install_mongodb ;;
    "postgresql") install_postgresql ;;
    "mysql") install_mysql ;;
    *) log_error "Invalid default database: $DEFAULT_DB" ;;
esac

# Ask for additional databases
read -p "Would you like to install additional databases? [y/N] " install_more
if [[ $install_more =~ ^[Yy]$ ]]; then
    echo "Select additional databases to install:"
    echo "1) MongoDB"
    echo "2) PostgreSQL"
    echo "3) MySQL"
    echo "4) Redis"
    echo "5) SQLite"
    echo "6) Elasticsearch"
    read -p "Enter numbers (space-separated): " selections
    
    for selection in $selections; do
        case $selection in
            1) [ "$DEFAULT_DB" != "mongodb" ] && install_mongodb ;;
            2) [ "$DEFAULT_DB" != "postgresql" ] && install_postgresql ;;
            3) [ "$DEFAULT_DB" != "mysql" ] && install_mysql ;;
            4) install_redis ;;
            5) install_sqlite ;;
            6) install_elasticsearch ;;
            *) log_warn "Invalid selection: $selection" ;;
        esac
    done
fi

# Install recommended packages if configured
if [ "$(get_config_value INSTALL_RECOMMENDED_PACKAGES true)" = "true" ]; then
    install_package "postgresql-client"
    install_package "mysql-client"
    install_package "redis-tools"
fi

log_info "Database Systems installation completed!"