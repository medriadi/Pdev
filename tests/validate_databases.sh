#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Validating database installations..."

# Test PostgreSQL
test_postgresql() {
    if command_exists "psql"; then
        if sudo -u postgres psql -c '\l' >/dev/null 2>&1; then
            if sudo -u postgres createdb test_db && \
               sudo -u postgres psql -d test_db -c 'CREATE TABLE test (id serial PRIMARY KEY, name VARCHAR);' && \
               sudo -u postgres psql -d test_db -c "INSERT INTO test (name) VALUES ('test');" && \
               sudo -u postgres psql -d test_db -c 'SELECT * FROM test;' | grep -q 'test'; then
                sudo -u postgres dropdb test_db
                log_info "PostgreSQL: OK"
                return 0
            fi
        fi
    fi
    log_error "PostgreSQL validation failed"
    return 1
}

# Test MySQL
test_mysql() {
    if command_exists "mysql"; then
        if mysql -u root -e "CREATE DATABASE IF NOT EXISTS test_db;
            USE test_db;
            CREATE TABLE IF NOT EXISTS test (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255));
            INSERT INTO test (name) VALUES ('test');
            SELECT * FROM test;" 2>/dev/null | grep -q 'test'; then
            mysql -u root -e "DROP DATABASE test_db;" 2>/dev/null
            log_info "MySQL: OK"
            return 0
        fi
    fi
    log_error "MySQL validation failed"
    return 1
}

# Test MongoDB
test_mongodb() {
    if command_exists "mongosh"; then
        if echo 'db.test.insert({name: "test"})' | mongosh --quiet test_db && \
           echo 'db.test.find()' | mongosh --quiet test_db | grep -q 'test'; then
            echo 'db.dropDatabase()' | mongosh --quiet test_db
            log_info "MongoDB: OK"
            return 0
        fi
    fi
    log_error "MongoDB validation failed"
    return 1
}

# Test Redis
test_redis() {
    if command_exists "redis-cli"; then
        if redis-cli ping | grep -q 'PONG' && \
           redis-cli set test_key "test_value" | grep -q 'OK' && \
           redis-cli get test_key | grep -q 'test_value'; then
            redis-cli del test_key
            log_info "Redis: OK"
            return 0
        fi
    fi
    log_error "Redis validation failed"
    return 1
}

# Test SQLite
test_sqlite() {
    if command_exists "sqlite3"; then
        if echo "CREATE TABLE test(id INTEGER PRIMARY KEY, name TEXT);
                INSERT INTO test(name) VALUES('test');
                SELECT * FROM test;" | sqlite3 :memory: | grep -q 'test'; then
            log_info "SQLite: OK"
            return 0
        fi
    fi
    log_error "SQLite validation failed"
    return 1
}

# Run all tests
test_postgresql
test_mysql
test_mongodb
test_redis
test_sqlite