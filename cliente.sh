#!/bin/bash

# ==============================
# VARIÁVEIS
# ==============================
LDAP_SERVER="192.168.1.92"
BASE_DN="dc=ambientesoperativos,dc=pt"
DOMAIN="ambientesoperativos.pt"

echo "🔧 Atualizar sistema"
apt update -y

echo "🔐 Instalar pacotes LDAP"
DEBIAN_FRONTEND=noninteractive apt install -y \
libnss-ldap \
libpam-ldap \
ldap-utils \
libpam-mkhomedir \
nscd

# ==============================
echo "🧠 Configurar LDAP cliente"
# ==============================
cat <<EOF > /etc/ldap/ldap.conf
BASE $BASE_DN
URI ldap://$LDAP_SERVER
EOF

# ==============================
echo "📇 Atualizar NSS"
# ==============================
sed -i 's/^passwd:.*/passwd: files ldap/' /etc/nsswitch.conf
sed -i 's/^group:.*/group: files ldap/' /etc/nsswitch.conf
sed -i 's/^shadow:.*/shadow: files ldap/' /etc/nsswitch.conf

# ==============================
echo "📂 Criar home automática"
# ==============================
grep -q pam_mkhomedir /etc/pam.d/common-session || \
echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session

systemctl restart nscd

# ==============================
echo "🌐 Configurar DNS"
# ==============================
cat <<EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=$LDAP_SERVER
Domains=$DOMAIN
EOF

systemctl restart systemd-resolved
resolvectl flush-caches

# ==============================
echo "🔎 Teste LDAP"
# ==============================
getent passwd aluno || echo "⚠️ Utilizador LDAP ainda não visível (reinicia)"

echo "✅ CLIENTE CONFIGURADO — REINICIA O SISTEMA"
