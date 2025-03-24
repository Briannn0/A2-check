#!/bin/bash

# a2-check.bash
# Author: Dao Tuan Anh Nguyen
# Date: March 24, 2025
# Purpose: Check if the LAMP stack and WordPress are configured correctly for Assignment 2
# Usage: Run with sudo on your Ubuntu VM

# Function to display status (OK or WARNING)
function check() {
  if eval $1
  then
     echo -e "\e[0;32mOK\e[m - $3"
  else
     echo -e "\e[0;31mWARNING\e[m - $2"
     ((WARNING_COUNT++))
  fi
}

clear
WARNING_COUNT=0

# Check if running as root
if [ $(whoami) != "root" ]
then
  echo "You must run this script as root. Please use sudo."
  exit 1
fi

# Get username
USER=${SUDO_USER:-$USER}
HOSTNAME=$(hostname)

echo "===== Assignment 2 Configuration Check ====="
echo "Username: $USER"
echo "Hostname: $HOSTNAME"
echo "Date: $(date)"
echo "============================================"
echo

# Check 1: Verify system is set to multi-user.target (CLI)
echo -n "Checking if system is set to CLI mode: "
check "systemctl get-default | grep -q 'multi-user.target'" "System is not set to CLI mode" "System is configured for CLI mode"

# Check 2: Verify static IP is set correctly
echo -n "Checking if static IP is configured correctly: "
check "ip addr show | grep -q '192.168.245.5'" "Static IP 192.168.245.5 is not configured" "Static IP is configured correctly"

# Check 3: Verify hostname resolution
echo -n "Checking hostname resolution in /etc/hosts: "
check "grep -q '$USER.*192.168.245.5' /etc/hosts" "Hostname resolution for $USER-ubuntu is not configured in /etc/hosts" "Hostname resolution is configured correctly"

# Check 4: Check installed packages
echo -n "Checking if Apache is installed: "
check "dpkg -l | grep -q 'apache2'" "Apache is not installed" "Apache is installed"

echo -n "Checking if PHP is installed: "
check "dpkg -l | grep -q 'php'" "PHP is not installed" "PHP is installed"

echo -n "Checking if PHP-MySQL is installed: "
check "dpkg -l | grep -q 'php-mysql'" "PHP-MySQL is not installed" "PHP-MySQL is installed"

echo -n "Checking if MariaDB is installed: "
check "dpkg -l | grep -q 'mariadb-server'" "MariaDB is not installed" "MariaDB is installed"

echo -n "Checking if WordPress is installed: "
check "dpkg -l | grep -q 'wordpress'" "WordPress is not installed" "WordPress is installed"

echo -n "Checking if nftables is installed: "
check "dpkg -l | grep -q 'nftables'" "nftables is not installed" "nftables is installed"

# Check 5: Verify services are running
echo -n "Checking if Apache is running: "
check "systemctl is-active apache2 &>/dev/null" "Apache is not running" "Apache is running"

echo -n "Checking if Apache is enabled at boot: "
check "systemctl is-enabled apache2 &>/dev/null" "Apache is not enabled at boot" "Apache is enabled at boot"

echo -n "Checking if MariaDB is running: "
check "systemctl is-active mariadb &>/dev/null" "MariaDB is not running" "MariaDB is running"

echo -n "Checking if MariaDB is enabled at boot: "
check "systemctl is-enabled mariadb &>/dev/null" "MariaDB is not enabled at boot" "MariaDB is enabled at boot"

echo -n "Checking if nftables is running: "
check "systemctl is-active nftables &>/dev/null" "nftables is not running" "nftables is running"

echo -n "Checking if nftables is enabled at boot: "
check "systemctl is-enabled nftables &>/dev/null" "nftables is not enabled at boot" "nftables is enabled at boot"

echo -n "Checking if UFW is disabled: "
check "! systemctl is-active ufw &>/dev/null && ! systemctl is-enabled ufw &>/dev/null" "UFW is still active or enabled" "UFW is correctly disabled"

# Check 6: Verify firewall rules
echo -n "Checking if default INPUT policy is set to DROP: "
check "iptables -L | grep -q 'Chain INPUT (policy DROP)'" "Default INPUT policy is not set to DROP" "Default INPUT policy is set to DROP"

echo -n "Checking if HTTP traffic is allowed: "
check "iptables -L | grep -q 'tcp dpt:http'" "HTTP traffic rule is not configured" "HTTP traffic is allowed"

echo -n "Checking if SSH traffic is allowed: "
check "iptables -L | grep -q 'tcp dpt:ssh'" "SSH traffic rule is not configured" "SSH traffic is allowed"

echo -n "Checking if established connections are allowed: "
check "iptables -L | grep -q 'RELATED,ESTABLISHED'" "Rule for established connections is not configured" "Established connections are allowed"

echo -n "Checking if DNS lookup is allowed: "
check "iptables -L | grep -q 'udp dpt:domain'" "DNS lookup rule is not configured" "DNS lookup is allowed"

# Check 7: Verify WordPress configuration
echo -n "Checking if WordPress virtual host is configured: "
check "test -f /etc/apache2/sites-available/wordpress.conf" "WordPress virtual host file is not created" "WordPress virtual host file exists"

echo -n "Checking if WordPress site is enabled: "
check "test -f /etc/apache2/sites-enabled/wordpress.conf" "WordPress site is not enabled" "WordPress site is enabled"

echo -n "Checking if WordPress config file exists: "
check "test -f /etc/wordpress/config-$USER-ubuntu.php" "WordPress config file is not created" "WordPress config file exists"

echo -n "Checking if WordPress config file has correct database settings: "
check "grep -q \"define('DB_NAME', 'myblog')\" /etc/wordpress/config-$USER-ubuntu.php" "WordPress config file does not have correct database name" "WordPress database name is correctly configured"

# Check 8: Test web server connectivity
echo -n "Checking if Apache is responding: "
check "curl -s http://localhost >/dev/null" "Apache is not responding" "Apache is responding"

echo -n "Checking if WordPress is accessible: "
check "curl -s http://localhost/blog/ >/dev/null" "WordPress is not accessible" "WordPress is accessible"

# Final results
echo
echo "============================================"
if [ $WARNING_COUNT -eq 0 ]; then
  echo -e "\e[0;32mCongratulations! All checks passed. Your Assignment 2 setup appears to be correctly configured.\e[m"
else
  echo -e "\e[0;31mWarning! $WARNING_COUNT checks failed. Please fix the issues highlighted above.\e[m"
fi
echo "============================================"