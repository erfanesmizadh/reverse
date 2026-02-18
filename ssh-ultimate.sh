#!/bin/bash

### CONFIG ###
SERVICE_NAME="reverse-tunnel"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}@.service"
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[36m"
NC="\e[0m"

### ROOT CHECK ###
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Run as root${NC}"
  exit 1
fi

### FUNCTIONS ###

banner() {
clear
echo -e "${BLUE}"
cat <<EOF
██████╗ ███████╗██╗   ██╗███████╗██████╗ ███████╗
██╔══██╗██╔════╝██║   ██║██╔════╝██╔══██╗██╔════╝
██████╔╝█████╗  ██║   ██║█████╗  ██████╔╝███████╗
██╔══██╗██╔══╝  ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║
██║  ██║███████╗ ╚████╔╝ ███████╗██║  ██║███████║
╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝

        U L T I M A T E   R E V E R S E   S S H
EOF
echo -e "${NC}"
}

pause() {
read -p "Press Enter to continue..."
}

install_autossh() {
echo -e "${YELLOW}Installing autossh...${NC}"
apt update -y && apt install autossh -y
}

generate_key() {
if [[ ! -f ~/.ssh/id_rsa ]]; then
echo -e "${YELLOW}Generating SSH key...${NC}"
ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
else
echo -e "${GREEN}SSH key already exists${NC}"
fi
}

create_service() {
read -p "Enter IRAN Server IP: " IRAN_IP
read -p "SSH User [root]: " SSH_USER
SSH_USER=${SSH_USER:-root}

echo -e "${YELLOW}Enter ports separated by space (e.g. 80 443 2087)${NC}"
read -p "Ports: " PORTS

ssh-copy-id ${SSH_USER}@${IRAN_IP}

cat <<EOF > $SERVICE_FILE
[Unit]
Description=Reverse SSH Tunnel %i
After=network-online.target

[Service]
User=root
ExecStart=/usr/bin/autossh -M 0 -N \\
 -o ServerAliveInterval=30 \\
 -o ServerAliveCountMax=3 \\
 -o ExitOnForwardFailure=yes \\
 -R 0.0.0.0:%i:localhost:%i ${SSH_USER}@${IRAN_IP}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

for P in $PORTS; do
systemctl enable ${SERVICE_NAME}@${P}
systemctl restart ${SERVICE_NAME}@${P}
done

echo -e "${GREEN}Tunnel(s) created successfully${NC}"
}

list_tunnels() {
systemctl list-units --type=service | grep ${SERVICE_NAME}
}

remove_tunnel() {
read -p "Enter port to remove: " P
systemctl stop ${SERVICE_NAME}@${P}
systemctl disable ${SERVICE_NAME}@${P}
rm -f /etc/systemd/system/${SERVICE_NAME}@${P}.service
echo -e "${GREEN}Tunnel removed${NC}"
}

check_listen() {
echo -e "${YELLOW}Listening ports (run on IRAN server):${NC}"
echo "-------------------------------------"
ss -tulpn | grep LISTEN
}

enable_bbr() {
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
echo -e "${GREEN}BBR Enabled${NC}"
}

### MENU ###
while true; do
banner
echo -e "${GREEN}[1] Install autossh"
echo "[2] Generate SSH key"
echo "[3] Create Reverse Tunnel"
echo "[4] List Active Tunnels"
echo "[5] Remove Tunnel"
echo "[6] Check LISTEN Ports"
echo "[7] Enable TCP BBR"
echo "[0] Exit${NC}"
echo ""
read -p "Select option: " opt

case $opt in
1) install_autossh ;;
2) generate_key ;;
3) create_service ;;
4) list_tunnels ;;
5) remove_tunnel ;;
6) check_listen ;;
7) enable_bbr ;;
0) exit ;;
*) echo "Invalid option" ;;
esac

pause
done
