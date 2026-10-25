
DNS Poisoning and Detection in a Virtual Machine Lab
A comprehensive cybersecurity project demonstrating DNS redirection, multi-vector detection, and defensive mitigation in an isolated virtual machine environment.

Project Metadata
Author: Tethi Das
Enrollment No: 241370107080
Branch: BE – Computer Engineering
University: Gujarat Technological University (GTU)
Project Guide: Prof. Deepak Upadhyay
Subject: Operating Systems (OS)
Demonstration Date: April 2026

Project Overview & Abstract
The Domain Name System (DNS) translates human-readable domain names into machine-readable IP addresses. Conceived in the 1980s for a small, trusted academic network, DNS lacks built-in cryptographic authentication, making it vulnerable to cache poisoning and query redirection.
This project documents a hands-on lab demonstration conducted across two virtual machines hosted on a MacBook M4:
Kali Linux (Attacker): Deploys a custom Python rogue DNS server (fakeDNS.py) using dnslib and hosts an Apache web server displaying an educational warning page.
Ubuntu 24.04 LTS (Victim): Acts as the target machine, performing DNS resolution, running detection diagnostics (tshark, dig, nslookup, arpwatch), and applying defensive mitigations.

Lab Environment Architecture
Host Machine: MacBook M4 (Apple Silicon) running macOS Sequoia via VMware Fusion & UTM.
Network Mode: Bridged Networking (192.168.1.x subnet).
Machine Role
Operating System
IP Address
MAC Address
Hypervisor
Key Tools
Attacker
Kali Linux 2024
192.168.1.13
00:0c:29:07:7b:f0
VMware Fusion
fakeDNS.py, Apache2, dsniff
Victim
Ubuntu 24.04 LTS
192.168.1.10
6e:1e:0b:eb:6b:2e
UTM (QEMU)
tshark, dig, nslookup, arpwatch


Technologies and Tools
Python 3 & dnslib: Used to construct the lightweight 40-line rogue DNS server (fakeDNS.py).
Apache2: Web server hosting the fake "DNS POISONED!" warning page on port 80.
tshark: Command-line network packet analyzer used to capture and inspect UDP port 53 traffic.
dig & nslookup: DNS troubleshooting tools used to compare poisoned responses against trusted public resolvers (@8.8.8.8).
arpwatch: Network daemon monitoring Ethernet/IP address changes for anomaly detection.

Project Directory Structure
dns-poisoning-detection/
├── README.md
├── kali_attack.sh
├── ubuntu_victim.sh
├── fakeDNS.py
├── fake_webpage.html
├── dnsspoof.hosts
├── screenshots/
│   ├── vm-setup.png
│   ├── dns-test.png
│   └── detection-output.png
├── docs/
│   ├── project-report.pdf
│   └── project-presentation.pptx
└── demo/
    └── README.md

Demonstration Video Recordings
Watch the live lab execution and step-by-step walkthroughs below:
🔴 Kali Linux Attacker Demonstration Video: https://drive.google.com/file/d/1dxTKyoktIVj934A5t7nL4P-WSNZ-wjGe/view?usp=sharing
🟡 Ubuntu 24.04 Victim & Defense Demonstration Video: https://drive.google.com/file/d/11i3XKaKD24BQd0zSNY5HDPruQXxGEP42/view?usp=sharing

Demonstration Workflow
Phase 1: Attack (Kali Linux)
Reconnaissance & Setup: Verify network connectivity between VMs via ip a and ping.
IP Forwarding: Enable kernel packet forwarding (echo 1 > /proc/sys/net/ipv4/ip_forward) to maintain victim internet connectivity and ensure attack stealth.
Hosts Configuration: Map target domains (www.google.com, *.google.com, facebook.com, example.com) to Kali's IP (192.168.1.13) in /etc/dnsspoof.hosts.
Rogue DNS Execution: Run fakeDNS.py to intercept all incoming UDP port 53 requests and return malicious A-records with a low TTL (60s).
Phase 2: Attack Impact (Ubuntu Victim)
Point Ubuntu's resolver (/etc/resolv.conf) to Kali (192.168.1.13).
Querying domains via dig or visiting via curl transparently resolves to Kali, displaying the warning page: YOU HAVE BEEN DNS POISONED!.
Phase 3: Detection & Analysis (5 Methods)
dig Comparison: Highlights discrepancies in returned IPs, short TTLs (60s vs 300s+), and unnatural query times (2ms vs 22ms) compared to @8.8.8.8.
nslookup Inspection: Exposes private LAN IP addresses acting as the primary DNS server.
tshark Packet Capture: Captures UDP port 53 traffic proving responses originate from Kali (192.168.1.13).
ARP Table Analysis: Inspects local MAC bindings via arp -n.
arpwatch Daemon: Tracks network mapping changes and logs alerts.
Phase 4: Mitigation & Defense (4 Strategies)
Flush Cache: Clear stale/poisoned entries immediately using sudo resolvectl flush-caches.
Restore Real DNS: Revert resolver configuration back to a trusted public server (nameserver 8.8.8.8).
Enable DNSSEC: Enforce cryptographic signature validation by setting DNSSEC=yes in /systemd/resolved.conf.
Static ARP Binding: Lock gateway MAC addresses using sudo arp -s to prevent ARP-based spoofing.

Automation Scripts
The project includes two automated shell scripts with color-coded logging and step confirmations:
kali_attack.sh: Automates 9 steps including tool validation, IP forwarding, hosts file generation, Apache deployment, and rogue DNS activation.
ubuntu_victim.sh: Automates 15 steps covering baseline state recording, attack verification, multi-method detection, cache flushing, DNS restoration, and DNSSEC enforcement.

Results & Verification Summary
Attack Success: 100% transparent redirection of all targeted domains to the attacker's IP with zero browser warnings over HTTP.
Detection Efficacy: Successfully identified anomalies across network, transport, and application layers using tshark and dig.
Defense Validation: Complete restoration of normal resolution flow and cryptographic integrity upon executing mitigation steps.

Safety & Ethical Notice
Disclaimer: This project was executed strictly within an isolated, authorized virtual lab environment for academic and educational purposes (Gujarat Technological University). Unauthorized network spoofing or DNS manipulation on public or third-party networks violates cybersecurity laws (including Section 66 of the IT Act).

License
Intended for academic reference and educational use.
