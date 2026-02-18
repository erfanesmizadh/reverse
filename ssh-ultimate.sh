#!/bin/bash

clear

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
END="\e[0m"

echo -e "${CYAN}"
echo "███╗   ███╗ ██████╗ ███╗   ██╗███████╗████████╗███████╗██████╗"
echo "████╗ ████║██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗"
echo "██╔████╔██║██║   ██║██╔██╗ ██║███████╗   ██║   █████╗  ██████╔╝"
echo "██║╚██╔╝██║██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══╝  ██╔══██╗"
echo "██║ ╚═╝ ██║╚██████╔╝██║ ╚████║███████║   ██║   ███████╗██║  ██║"
echo -e "${END}"

echo "🔥 MONSTER SSH TUNNEL 🔥"

# install deps
install_deps() {

apt update -y
apt install autossh -y

}

generate_key() {

if [ ! -f ~/.ssh/id_rsa ]; then
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

echo -e "${GREEN}Public Key:${END}"
cat ~/.ssh/id_rsa.pub

}

copy_key() {

read -p "Remote Server IP: " RIP
read -p "Remote User: " RUSER

ssh-copy-id ${RUSER}@${RIP}

}

reverse_tunnel() {

read -p "IRAN Server IP: " IP
read -p "IRAN SSH USER: " USER
read -p "IRAN SSH PORT: " SSHPORT
read -p "PORT (example 2100): " PORT

cat <<EOF > /etc/systemd/system/reverse-tunnel@${PORT}.service

[Unit]
Description=Monster Reverse SSH Tunnel
After=network.target

[Service]
User=root
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -p ${SSHPORT} -R ${PORT}:localhost:${PORT} ${USER}@${IP}
Restart=always

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable reverse-tunnel@${PORT}
systemctl start reverse-tunnel@${PORT}

echo "🔥 Reverse tunnel started on port ${PORT}"

}

forward_tunnel() {

read -p "Remote Server IP: " IP
read -p "Remote SSH USER: " USER
read -p "SSH PORT: " SSHPORT
read -p "LOCAL PORT: " LPORT
read -p "REMOTE DEST PORT: " RPORT

cat <<EOF > /etc/systemd/system/forward-tunnel@${LPORT}.service

[Unit]
Description=Monster Forward SSH Tunnel
After=network.target

[Service]
User=root
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -p ${SSHPORT} -L ${LPORT}:localhost:${RPORT} ${USER}@${IP}
Restart=always

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable forward-tunnel@${LPORT}
systemctl start forward-tunnel@${LPORT}

echo "🔥 Forward tunnel started"

}

status_check() {

systemctl list-units | grep tunnel

}

while true; do

echo ""
echo "1) Install Dependencies"
echo "2) Generate SSH Key"
echo "3) Copy SSH Key to Remote"
echo "4) Create Reverse Tunnel (OUTSIDE -> IRAN)"
echo "5) Create Forward Tunnel"
echo "6) Show Tunnel Status"
echo "0) Exit"

read -p "Select option: " opt

case $opt in

1) install_deps ;;
2) generate_key ;;
3) copy_key ;;
4) reverse_tunnel ;;
5) forward_tunnel ;;
6) status_check ;;
0) exit ;;

esac

done
