#!/bin/bash

# Colores para la terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Arte ASCII y Presentación
clear
echo -e "${CYAN}"
echo "██╗   ██╗███████╗████████╗████████╗██████╗ ██╗  ██╗"
echo "██║   ██║██╔════╝╚══██╔══╝╚══██╔══╝╚════██╗╚██╗██╔╝"
echo "██║   ██║█████╗     ██║      ██║    █████╔╝ ╚███╔╝ "
echo "██╚╗ ██╔╝██╔══╝     ██║      ██║    ╚═══██╗ ██╔██╗ "
echo " ╚████╔╝ ███████╗   ██║      ██║   ██████╔╝██╔╝ ██╗"
echo "  ╚═══╝  ╚══════╝   ╚═╝      ╚═╝   ╚═════╝ ╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "${BLUE}===================================================${NC}"
echo -e "${GREEN}      S U P A B A S E   A U T H E N T I C A T O R    ${NC}"
echo -e "${BLUE}             Created by: Vett3x                    ${NC}"
echo -e "${BLUE}===================================================${NC}"
echo -e "Este proyecto asegura tu instalación autoalojada de "
echo -e "Supabase con un portal de acceso seguro y moderno."
echo -e "${BLUE}---------------------------------------------------${NC}"

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Por favor, ejecuta este script como root (sudo).${NC}"
  exit 1
fi

# Pedir credenciales personalizadas
echo -e "${CYAN}Configuración de acceso al panel:${NC}"
read -p "Introduce el Email para el panel: " ADMIN_EMAIL
read -s -p "Introduce la Contraseña para el panel: " ADMIN_PASS
echo ""

# 0. Preparación del Entorno
echo -e "${GREEN}[0/5] Verificando y preparando el entorno...${NC}"
apt-get update && apt-get install -y curl git openssl build-essential jq

# Instalar Docker y Node.js si no existen
if ! [ -x "$(command -v docker)" ]; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh
fi
if ! [ -x "$(command -v docker-compose)" ]; then
    apt-get install -y docker-compose
fi
if ! [ -x "$(command -v node)" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs
fi

# 1. Clonar Supabase
echo -e "${GREEN}[1/5] Descargando Supabase...${NC}"
if [ ! -d "supabase" ]; then
    git clone --depth 1 https://github.com/supabase/supabase.git
fi

# 2. Configurar Supabase
echo -e "${GREEN}[2/5] Configurando Supabase...${NC}"
cd supabase/docker
if [ ! -f ".env" ]; then
    cp .env.example .env
    DB_PASS=$(openssl rand -hex 16)
    JWT_SEC=$(openssl rand -hex 32)
    ANON_K=$(openssl rand -hex 64)
    SERVICE_K=$(openssl rand -hex 64)
    sed -i "s/POSTGRES_PASSWORD=postgres/POSTGRES_PASSWORD=$DB_PASS/g" .env
    sed -i "s/JWT_SECRET=super-secret-jwt-token-with-at-least-32-characters-long/JWT_SECRET=$JWT_SEC/g" .env
    sed -i "s/ANON_KEY=.*$/ANON_KEY=$ANON_K/g" .env
    sed -i "s/SERVICE_ROLE_KEY=.*$/SERVICE_ROLE_KEY=$SERVICE_K/g" .env
fi
docker-compose up -d
cd ../..

# 3. Configurar el Panel
echo -e "${GREEN}[3/5] Configurando el Panel...${NC}"
PANEL_JWT=$(openssl rand -hex 32)
echo "JWT_SECRET=$PANEL_JWT" > .env.local
echo "SUPABASE_STUDIO_URL=http://localhost:8000" >> .env.local
echo "AUTH_PASSWORD=$ADMIN_PASS" >> .env.local

# 4. Instalación y Build
echo -e "${GREEN}[4/5] Instalando y Construyendo...${NC}"
npm install
npm run build

# 5. Herramientas CLI y Persistencia
echo -e "${GREEN}[5/5] Instalando herramientas CLI...${NC}"

# Comando para cambiar contraseña
cat <<EOF > /usr/local/bin/supabase-auth-passwd
#!/bin/bash
if [ -z "\$1" ] || [ -z "\$2" ]; then
    echo "Uso: supabase-auth-passwd <nuevo_email> <nueva_pass>"
    exit 1
fi
node $(pwd)/scripts/change-password-cli.js "\$1" "\$2"
EOF
chmod +x /usr/local/bin/supabase-auth-passwd

# Comando para backup
cat <<EOF > /usr/local/bin/supabase-auth-backup
#!/bin/bash
BACKUP_DIR="$(pwd)/backups"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
mkdir -p \$BACKUP_DIR
echo "Iniciando backup completo..."
# Backup de la DB del panel
cp $(pwd)/auth.db \$BACKUP_DIR/panel_db_\$TIMESTAMP.sqlite
# Backup de la DB de Supabase
docker exec supabase-db pg_dumpall -U postgres > \$BACKUP_DIR/supabase_full_\$TIMESTAMP.sql
echo "Backup completado en: \$BACKUP_DIR"
EOF
chmod +x /usr/local/bin/supabase-auth-backup

# Persistencia Systemd
cat <<EOF > /etc/systemd/system/supabase-auth.service
[Unit]
Description=Supabase Authenticator Panel
After=network.target docker.service
[Service]
Type=simple
User=root
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/npm start
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable supabase-auth.service && systemctl start supabase-auth.service

# Finalización con Info del Servidor
clear
echo -e "${CYAN}===================================================${NC}"
echo -e "${GREEN}      INSTALACIÓN COMPLETADA POR VETT3X             ${NC}"
echo -e "${CYAN}===================================================${NC}"
echo -e "${BLUE}INFORMACIÓN DEL PANEL:${NC}"
echo -e "URL de Acceso: http://$(hostname -I | awk '{print $1}'):3000"
echo -e "Email: $ADMIN_EMAIL"
echo -e "Password: (La que introdujiste)"
echo -e ""
echo -e "${BLUE}INFORMACIÓN DE SUPABASE (INTERNO):${NC}"
echo -e "Postgres Password: $DB_PASS"
echo -e "JWT Secret: $JWT_SEC"
echo -e "Anon Key: $ANON_K"
echo -e "Service Role Key: $SERVICE_K"
echo -e ""
echo -e "${BLUE}COMANDOS ÚTILES DEL SISTEMA:${NC}"
echo -e "Cambiar acceso: ${YELLOW}supabase-auth-passwd <email> <pass>${NC}"
echo -e "Realizar backup: ${YELLOW}supabase-auth-backup${NC}"
echo -e "Ver logs: ${YELLOW}journalctl -u supabase-auth -f${NC}"
echo -e "${CYAN}===================================================${NC}"

# Inicializar la base de datos con el email/pass proporcionado
node scripts/change-password-cli.js "$ADMIN_EMAIL" "$ADMIN_PASS"
