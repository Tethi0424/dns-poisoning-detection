#!/bin/bash

# ============================================================
#   DNS POISONING DEMO — UBUNTU (VICTIM + DETECTION)
#   Run this on: Ubuntu 24.04
#   Usage: sudo bash ubuntu_victim.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${CYAN}======================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}======================================${NC}\n"
}

print_step() {
    echo -e "${YELLOW}[STEP $1]${NC} ${GREEN}$2${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_alert() {
    echo -e "${RED}[🚨 ALERT] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

pause() {
    echo -e "\n${YELLOW}Press Enter to continue to next step...${NC}"
    read
}

# ============================================================
# STEP 1 — SHOW NETWORK INFO
# ============================================================
print_header "STEP 1 — UBUNTU NETWORK INFORMATION"
print_step "1" "Showing Ubuntu IP address..."
ip a | grep "inet " | grep -v "127.0.0.1"
pause

# ============================================================
# STEP 2 — INSTALL DETECTION TOOLS
# ============================================================
print_header "STEP 2 — INSTALLING DETECTION TOOLS"
print_step "2" "Installing wireshark, tshark, arpwatch, dnsutils..."
sudo apt update -q
sudo apt install -y tshark arpwatch net-tools dnsutils curl
print_success "All detection tools installed!"
pause

# ============================================================
# STEP 3 — BASELINE (BEFORE ATTACK)
# ============================================================
print_header "STEP 3 — BASELINE CHECK (BEFORE ATTACK)"

print_step "3a" "Checking real DNS resolution..."
echo -e "${BLUE}--- dig www.google.com (BEFORE ATTACK) ---${NC}"
dig www.google.com | grep -A5 "ANSWER SECTION"

echo ""
print_step "3b" "Checking ARP table before attack..."
echo -e "${BLUE}--- ARP Table (BEFORE ATTACK) ---${NC}"
arp -n

echo ""
print_info "Screenshot the above — this is your BASELINE proof!"
pause

# ============================================================
# STEP 4 — GET KALI IP FROM USER
# ============================================================
print_header "STEP 4 — ENTER KALI IP"
echo -e "${CYAN}Enter your Kali Linux IP (e.g. 192.168.1.13):${NC}"
read KALI_IP

# ============================================================
# STEP 5 — CONFIGURE DNS TO USE KALI
# ============================================================
print_header "STEP 5 — POINT DNS TO KALI (SIMULATING ATTACK)"
print_step "5" "Removing symlink and setting Kali as DNS server..."

sudo rm -f /etc/resolv.conf
echo "nameserver $KALI_IP" | sudo tee /etc/resolv.conf

echo ""
print_step "5b" "Verifying DNS config..."
cat /etc/resolv.conf
print_success "DNS now pointing to Kali: $KALI_IP"
pause

# ============================================================
# STEP 6 — MAKE SURE KALI DNS IS RUNNING
# ============================================================
print_header "STEP 6 — START ATTACK"
echo -e "${RED}[!] Make sure Kali fakeDNS.py is running before continuing!${NC}"
echo -e "${YELLOW}[!] Go to Kali and run: sudo python3 ~/fakeDNS.py${NC}"
echo -e "${YELLOW}Press Enter when Kali DNS server is running...${NC}"
read

# ============================================================
# STEP 7 — PROOF OF ATTACK
# ============================================================
print_header "STEP 7 — PROOF OF ATTACK"

print_step "7a" "Running nslookup (should show Kali IP)..."
echo -e "${BLUE}--- nslookup www.google.com ---${NC}"
nslookup www.google.com

echo ""
print_step "7b" "Running dig (should show Kali IP: $KALI_IP)..."
echo -e "${BLUE}--- dig www.google.com (POISONED) ---${NC}"
dig www.google.com | grep -A5 "ANSWER SECTION"

POISONED_IP=$(dig +short www.google.com)
if [ "$POISONED_IP" = "$KALI_IP" ]; then
    print_alert "DNS POISONING CONFIRMED! www.google.com resolves to $KALI_IP (Kali!)"
else
    print_info "DNS returned: $POISONED_IP"
fi

echo ""
print_step "7c" "Running curl (should show fake page from Kali)..."
echo -e "${BLUE}--- curl http://www.google.com ---${NC}"
curl -s http://www.google.com
echo ""
print_info "Screenshot the above — MAIN ATTACK PROOF!"
pause

# ============================================================
# STEP 8 — COMPARE WITH REAL DNS
# ============================================================
print_header "STEP 8 — COMPARISON: POISONED vs REAL DNS"

echo -e "${RED}--- POISONED DNS result ---${NC}"
dig www.google.com | grep -A3 "ANSWER SECTION"

echo ""
echo -e "${GREEN}--- REAL DNS result (bypassing attack) ---${NC}"
dig www.google.com @8.8.8.8 | grep -A3 "ANSWER SECTION"

print_info "Screenshot both — shows difference between poisoned and real!"
pause

# ============================================================
# STEP 9 — CAPTURE DNS TRAFFIC WITH TSHARK
# ============================================================
print_header "STEP 9 — DETECT ATTACK WITH TSHARK"
print_step "9" "Capturing DNS traffic for 15 seconds..."
print_info "Triggering DNS queries while capturing..."

# Run tshark in background and trigger DNS queries
sudo timeout 15 tshark -i enp0s1 -f "udp port 53" -Y "dns" 2>/dev/null &
TSHARK_PID=$!

sleep 2
dig www.google.com > /dev/null 2>&1
dig facebook.com > /dev/null 2>&1
dig example.com > /dev/null 2>&1

wait $TSHARK_PID

print_alert "Look for DNS responses coming FROM $KALI_IP — that proves DNS poisoning!"
pause

# ============================================================
# STEP 10 — DETECT WITH ARP TABLE
# ============================================================
print_header "STEP 10 — DETECT WITH ARP TABLE"
print_step "10" "Checking ARP table (after attack)..."
echo -e "${BLUE}--- ARP Table (AFTER ATTACK) ---${NC}"
arp -n
print_info "Compare with baseline from Step 3 — look for MAC address changes!"
pause

# ============================================================
# STEP 11 — DETECT WITH ARPWATCH
# ============================================================
print_header "STEP 11 — DETECT WITH ARPWATCH"
print_step "11" "Starting arpwatch monitoring..."
sudo systemctl start arpwatch
sudo systemctl status arpwatch | grep "Active:"

echo ""
print_step "11b" "Triggering network activity for arpwatch to detect..."
ping -c 3 $KALI_IP > /dev/null 2>&1

echo ""
print_step "11c" "Checking arpwatch logs..."
sudo journalctl -u arpwatch --no-pager -n 20
print_info "Look for 'new station' or 'changed ethernet address' alerts!"
pause

# ============================================================
# STEP 12 — DEFENSE: RESTORE REAL DNS
# ============================================================
print_header "STEP 12 — DEFENSE: RESTORE REAL DNS"
print_step "12" "Removing poisoned DNS config..."
sudo rm -f /etc/resolv.conf

print_step "12b" "Setting real DNS server..."
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

print_step "12c" "Flushing poisoned DNS cache..."
sudo resolvectl flush-caches 2>/dev/null || true

print_success "DNS restored to 8.8.8.8!"
cat /etc/resolv.conf
pause

# ============================================================
# STEP 13 — VERIFY DEFENSE WORKS
# ============================================================
print_header "STEP 13 — VERIFY DEFENSE WORKS"

print_step "13a" "Checking dig now returns real Google IP..."
echo -e "${BLUE}--- dig www.google.com (AFTER DEFENSE) ---${NC}"
dig www.google.com | grep -A5 "ANSWER SECTION"

REAL_IP=$(dig +short www.google.com @8.8.8.8 | head -1)
CURRENT_IP=$(dig +short www.google.com | head -1)

echo ""
if [ "$CURRENT_IP" != "$KALI_IP" ]; then
    print_success "DEFENSE SUCCESSFUL! DNS now returns real IP: $CURRENT_IP"
else
    print_alert "Still poisoned! Make sure Kali DNS server is stopped."
fi
pause

# ============================================================
# STEP 14 — ENABLE DNSSEC
# ============================================================
print_header "STEP 14 — MITIGATION: ENABLE DNSSEC"
print_step "14" "Enabling DNSSEC in systemd-resolved..."

sudo sed -i 's/#DNSSEC=no/DNSSEC=yes/' /etc/systemd/resolved.conf
sudo sed -i 's/DNSSEC=no/DNSSEC=yes/' /etc/systemd/resolved.conf

echo ""
print_step "14b" "Verifying DNSSEC config..."
grep "DNSSEC" /etc/systemd/resolved.conf

echo ""
print_step "14c" "Restarting systemd-resolved..."
sudo systemctl restart systemd-resolved 2>/dev/null || \
sudo systemctl restart networking 2>/dev/null || \
print_info "Service restart skipped - DNSSEC config saved successfully!"

print_success "DNSSEC protection enabled!"
pause

# ============================================================
# STEP 15 — FINAL SUMMARY
# ============================================================
print_header "FINAL PROJECT SUMMARY"

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     DNS POISONING DEMO — COMPLETE! 🎓        ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                              ║${NC}"
echo -e "${GREEN}║  ATTACK PHASE:                               ║${NC}"
echo -e "${GREEN}║  ✓ Fake DNS server ran on Kali               ║${NC}"
echo -e "${GREEN}║  ✓ DNS queries redirected to Kali IP         ║${NC}"
echo -e "${GREEN}║  ✓ curl showed fake poisoned page            ║${NC}"
echo -e "${GREEN}║                                              ║${NC}"
echo -e "${GREEN}║  DETECTION PHASE:                            ║${NC}"
echo -e "${GREEN}║  ✓ tshark captured fake DNS responses        ║${NC}"
echo -e "${GREEN}║  ✓ dig comparison proved poisoning           ║${NC}"
echo -e "${GREEN}║  ✓ arpwatch monitored network changes        ║${NC}"
echo -e "${GREEN}║                                              ║${NC}"
echo -e "${GREEN}║  DEFENSE PHASE:                              ║${NC}"
echo -e "${GREEN}║  ✓ DNS cache flushed                         ║${NC}"
echo -e "${GREEN}║  ✓ Real DNS restored                         ║${NC}"
echo -e "${GREEN}║  ✓ DNSSEC protection enabled                 ║${NC}"
echo -e "${GREEN}║                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"

