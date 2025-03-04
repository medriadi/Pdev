#!/bin/bash

source "$(dirname "$0")/../common.sh"

log_info "Validating programming language installations..."

# Test Node.js
test_nodejs() {
    if command_exists "node"; then
        echo 'console.log("Hello from Node.js");' > test.js
        if node test.js | grep -q "Hello from Node.js"; then
            log_info "Node.js: OK"
            rm test.js
            return 0
        fi
    fi
    log_error "Node.js validation failed"
    return 1
}

# Test Python
test_python() {
    if command_exists "python3"; then
        if python3 -c "print('Hello from Python')" | grep -q "Hello from Python"; then
            # Test pip installation
            if python3 -m pip --version >/dev/null 2>&1; then
                log_info "Python and pip: OK"
                return 0
            fi
        fi
    fi
    log_error "Python validation failed"
    return 1
}

# Test Java
test_java() {
    if command_exists "java" && command_exists "javac"; then
        echo 'public class Test { public static void main(String[] args) { System.out.println("Hello from Java"); } }' > Test.java
        if javac Test.java && java Test | grep -q "Hello from Java"; then
            log_info "Java: OK"
            rm Test.java Test.class
            return 0
        fi
    fi
    log_error "Java validation failed"
    return 1
}

# Test Go
test_go() {
    if command_exists "go"; then
        echo 'package main; import "fmt"; func main() { fmt.Println("Hello from Go") }' > test.go
        if go run test.go | grep -q "Hello from Go"; then
            log_info "Go: OK"
            rm test.go
            return 0
        fi
    fi
    log_error "Go validation failed"
    return 1
}

# Test Rust
test_rust() {
    if command_exists "rustc"; then
        echo 'fn main() { println!("Hello from Rust"); }' > test.rs
        if rustc test.rs && ./test | grep -q "Hello from Rust"; then
            log_info "Rust: OK"
            rm test.rs test
            return 0
        fi
    fi
    log_error "Rust validation failed"
    return 1
}

# Run all tests
test_nodejs
test_python
test_java
test_go
test_rust