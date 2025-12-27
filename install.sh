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

# Detectar si es una actualización
IS_UPDATE=false
if [ -f ".env.local" ]; then
    IS_UPDATE=true
    echo -e "${BLUE}>>> Detectada instalación existente. Modo Actualización activado. <<<${NC}"
    ADMIN_EMAIL=$(grep "ADMIN_EMAIL" .env.local | cut -d'=' -f2) # Intentar recuperar si lo guardamos
else
    # Pedir credenciales personalizadas (Solo en instalación limpia)
    echo -e "${CYAN}Configuración de acceso al panel:${NC}"
    read -p "Introduce el Email para el panel: " ADMIN_EMAIL
    read -s -p "Introduce la Contraseña para el panel: " ADMIN_PASS
    echo ""
fi

# 0. Preparación del Entorno
echo -e "${GREEN}[0/5] Verificando y preparando el entorno...${NC}"

# Solución para error de docker-compose en Debian/Ubuntu con Python 3.12+
if [ -f /usr/lib/python3.12/dist-packages/compose/cli/main.py ] || [ -x "$(command -v apt-get)" ]; then
    echo -e "${BLUE}Asegurando compatibilidad de herramientas de sistema...${NC}"
    apt-get update && apt-get install -y python3-pip python3-setuptools
    # Instalar distutils que falta en Python 3.12+ para el docker-compose antiguo
    apt-get install -y python3-launchpadlib || true
fi

# Instalar Docker y Docker Compose V2 (el comando moderno es 'docker compose')
if ! [ -x "$(command -v docker)" ]; then
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh
fi

# Instalar el plugin de Docker Compose V2 si no está (evita problemas de Python/distutils)
if ! docker compose version >/dev/null 2>&1; then
    echo -e "${BLUE}Instalando Docker Compose V2 (Plugin)...${NC}"
    apt-get install -y docker-compose-plugin
fi
if ! [ -x "$(command -v node)" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs
fi

# 1. Clonar/Actualizar Supabase
echo -e "${GREEN}[1/5] Gestionando Supabase...${NC}"
if [ ! -d "supabase" ]; then
    git clone --depth 1 https://github.com/supabase/supabase.git
else
    echo -e "${BLUE}Actualizando repositorio de Supabase...${NC}"
    cd supabase && git pull && cd ..
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
else
    echo -e "${BLUE}Cargando configuración existente de Supabase...${NC}"
    DB_PASS=$(grep "POSTGRES_PASSWORD" .env | cut -d'=' -f2)
    JWT_SEC=$(grep "JWT_SECRET" .env | cut -d'=' -f2)
    ANON_K=$(grep "ANON_KEY" .env | cut -d'=' -f2)
    SERVICE_K=$(grep "SERVICE_ROLE_KEY" .env | cut -d'=' -f2)
fi
echo -e "${BLUE}Reiniciando contenedores...${NC}"
docker compose down
docker compose up -d
cd ../..

# 3. Configurar el Panel
echo -e "${GREEN}[3/5] Configurando el Panel...${NC}"
if [ "$IS_UPDATE" = false ]; then
    PANEL_JWT=$(openssl rand -hex 32)
    echo "JWT_SECRET=$PANEL_JWT" > .env.local
    echo "SUPABASE_STUDIO_URL=http://localhost:8000" >> .env.local
    echo "AUTH_PASSWORD=$ADMIN_PASS" >> .env.local
    echo "ADMIN_EMAIL=$ADMIN_EMAIL" >> .env.local
fi

# 4. Instalación y Build
echo -e "${GREEN}[4/5] Instalando y Construyendo...${NC}"
# Limpiar cache y builds anteriores para asegurar una instalación limpia
rm -rf .next
rm -rf node_modules
npm install
# Forzar el build y capturar errores
if ! npm run build; then
    echo -e "${RED}Error: El build de Next.js falló.${NC}"
    exit 1
fi
# Verificar que la carpeta .next existe después del build
if [ ! -d ".next" ]; then
    echo -e "${RED}Error: No se encontró la carpeta .next después del build.${NC}"
    exit 1
fi

# 5. Herramientas CLI y Persistencia
echo -e "${GREEN}[5/5] Actualizando herramientas CLI y Servicio...${NC}"

# Abrir puertos en el firewall si existe (ufw)
if command -v ufw >/dev/null 2>&1; then
    echo -e "${BLUE}Asegurando que los puertos 3000 y 8000 estén abiertos...${NC}"
    ufw allow 3000/tcp
    ufw allow 8000/tcp
fi

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
if [ -f "$(pwd)/auth.db" ]; then
    cp $(pwd)/auth.db \$BACKUP_DIR/panel_db_\$TIMESTAMP.sqlite
fi
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
Environment=HOSTNAME=0.0.0.0
Environment=PORT=3000
ExecStart=/usr/bin/npm start
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload && systemctl enable supabase-auth.service && systemctl restart supabase-auth.service

# Finalización
clear
echo -e "${CYAN}===================================================${NC}"
if [ "$IS_UPDATE" = true ]; then
    echo -e "${GREEN}      ACTUALIZACIÓN COMPLETADA POR VETT3X           ${NC}"
else
    echo -e "${GREEN}      INSTALACIÓN COMPLETADA POR VETT3X             ${NC}"
fi
echo -e "${CYAN}===================================================${NC}"
echo -e "${BLUE}INFORMACIÓN DEL PANEL:${NC}"
echo -e "URL de Acceso: http://$(hostname -I | awk '{print $1}'):3000"
if [ "$IS_UPDATE" = true ]; then
    echo -e "Email: (Configurado anteriormente)"
    echo -e "Password: (Configurada anteriormente)"
else
    echo -e "Email: $ADMIN_EMAIL"
    echo -e "Password: (La que introdujiste)"
fi
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

# Inicializar/Actualizar base de datos
if [ "$IS_UPDATE" = false ]; then
    node scripts/change-password-cli.js "$ADMIN_EMAIL" "$ADMIN_PASS"
fi
