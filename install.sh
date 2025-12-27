#!/bin/bash

# Colores para la terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Arte ASCII y Presentación (Se movió al bucle del menú)

# Verificar si se está ejecutando como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Por favor, ejecuta este script como root (sudo).${NC}"
  exit 1
fi

# --- FUNCIONES DE UTILIDAD ---

install_base_deps() {
    echo -e "${GREEN}[0/5] Verificando y preparando el entorno...${NC}"
    
    # 1. Actualizar repositorios
    apt-get update
    
    # 2. Instalar herramientas base
    apt-get install -y curl git openssl build-essential jq psmisc
    
    # 3. Instalar Docker si no existe
    if ! command -v docker &> /dev/null; then
        echo -e "${BLUE}Instalando Docker...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    fi
    
    # 4. Instalar Docker Compose V2 (Plugin)
    if ! docker compose version &> /dev/null; then
        echo -e "${BLUE}Instalando Docker Compose V2...${NC}"
        apt-get install -y docker-compose-plugin
    fi
    
    # 5. Instalar Node.js y NPM si no existen
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
        echo -e "${BLUE}Instalando Node.js 20.x y NPM...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
        # Forzar actualización de hash de comandos
        hash -r
    fi
}

show_credentials() {
    clear
    echo -e "${CYAN}===================================================${NC}"
    echo -e "${GREEN}      CREDENCIALES DE SUPABASE (Auto-generadas)     ${NC}"
    echo -e "${CYAN}===================================================${NC}"
    
    if [ -f "supabase/docker/.env" ]; then
        cd supabase/docker
        DB_PASS=$(grep "POSTGRES_PASSWORD" .env | cut -d'=' -f2)
        JWT_SEC=$(grep "JWT_SECRET" .env | cut -d'=' -f2)
        ANON_K=$(grep "ANON_KEY" .env | cut -d'=' -f2)
        SERVICE_K=$(grep "SERVICE_ROLE_KEY" .env | cut -d'=' -f2)
        cd ../..
        
        echo -e "${BLUE}Base de Datos (PostgreSQL):${NC}"
        echo -e "  Host: localhost"
        echo -e "  Puerto: 5432"
        echo -e "  Usuario: postgres"
        echo -e "  Password: ${YELLOW}$DB_PASS${NC}"
        echo -e ""
        echo -e "${BLUE}API Keys:${NC}"
        echo -e "  JWT Secret: ${YELLOW}$JWT_SEC${NC}"
        echo -e "  Anon Key: ${YELLOW}${ANON_K:0:20}...${NC}"
        echo -e "  Service Role Key: ${YELLOW}${SERVICE_K:0:20}...${NC}"
        echo -e ""
        echo -e "${BLUE}URLs Locales:${NC}"
        echo -e "  Studio: http://localhost:8000"
        echo -e "  API/Kong: http://localhost:8000"
    else
        echo -e "${RED}Error: Supabase aún no ha sido configurado.${NC}"
    fi
    echo -e "${CYAN}===================================================${NC}"
    read -p "Presiona Enter para volver al menú..."
}

show_logs() {
    echo -e "${BLUE}Mostrando logs de servicios (Ctrl+C para salir)...${NC}"
    docker compose -f supabase/docker/docker-compose.yml logs -f --tail=50
}

run_backup() {
    echo -e "${BLUE}Iniciando backup manual...${NC}"
    /usr/local/bin/supabase-auth-backup
    read -p "Presiona Enter para volver al menú..."
}

full_reinstall() {
    clear
    echo -e "${RED}⚠️  ADVERTENCIA: REINSTALACIÓN COMPLETA ⚠️${NC}"
    echo -e "${RED}---------------------------------------${NC}"
    echo -e "Esto eliminará:"
    echo -e "1. Todos los contenedores de Supabase"
    echo -e "2. Todos los volúmenes de datos (BASE DE DATOS COMPLETA)"
    echo -e "3. Configuración del panel y usuarios"
    echo -e ""
    echo -e "${YELLOW}Se recomienda hacer un Backup (Opción 3) antes de continuar.${NC}"
    echo -e ""
    read -p "¿ESTÁS SEGURO? Escribe 'REINSTALAR' para confirmar: " CONFIRM

    if [ "$CONFIRM" != "REINSTALAR" ]; then
        echo -e "${BLUE}Reinstalación cancelada.${NC}"
        sleep 2
        return
    fi

    echo -e "${RED}Iniciando limpieza total...${NC}"
    
    # 1. Detener y borrar contenedores y volúmenes
    if [ -d "supabase/docker" ]; then
        cd supabase/docker
        docker compose down -v
        cd ../..
    fi

    # 2. Eliminar carpetas y archivos de configuración
    echo -e "${BLUE}Borrando archivos y configuraciones...${NC}"
    rm -rf supabase
    rm -f .env.local
    rm -f auth.db
    rm -rf .next
    rm -rf node_modules
    
    # 3. Eliminar servicio systemd si existe
    if [ -f "/etc/systemd/system/supabase-auth.service" ]; then
        systemctl stop supabase-auth.service || true
        systemctl disable supabase-auth.service || true
        rm /etc/systemd/system/supabase-auth.service
        systemctl daemon-reload
    fi

    echo -e "${GREEN}Limpieza completada con éxito.${NC}"
    echo -e "${BLUE}Iniciando instalación desde cero...${NC}"
    sleep 2
    
    # Resetear variables y lanzar instalación normal
    IS_UPDATE=false
    run_install
}

# --- LÓGICA DE INSTALACIÓN PRINCIPAL ---

run_install() {
    # Asegurar que las dependencias base estén instaladas antes de nada
    install_base_deps

    # Detectar memoria RAM total para optimizar el build
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_RAM" -lt 1800 ]; then
        NODE_MEM=1024
    elif [ "$TOTAL_RAM" -lt 3500 ]; then
        NODE_MEM=2048
    else
        NODE_MEM=3072
    fi

    # Detectar espacio en disco (en GB)
    DISK_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$DISK_SPACE" -lt 10 ]; then
        echo -e "${RED}Error: Necesitas al menos 10GB de espacio libre.${NC}"
        exit 1
    fi

    # Detectar si es una actualización
    IS_UPDATE=false
    if [ -f ".env.local" ]; then
        IS_UPDATE=true
        echo -e "${BLUE}>>> Modo Actualización activado. <<<${NC}"
        ADMIN_EMAIL=$(grep "ADMIN_EMAIL" .env.local | cut -d'=' -f2)
    else
        echo -e "${CYAN}Configuración de acceso al panel:${NC}"
        read -p "Introduce el Email para el panel: " ADMIN_EMAIL
        read -s -p "Introduce la Contraseña para el panel: " ADMIN_PASS
        echo ""
    fi

# 0. Verificando y preparando el entorno (Ya se hizo en install_base_deps si es necesario)

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
    # Reintento de pull en caso de error de red (común en Proxmox/CT)
    echo -e "${BLUE}Descargando imágenes pesadas de Supabase...${NC}"
    echo -e "${YELLOW}Nota: Supabase ocupa ~4GB extraídos. El proceso puede parecer detenido en 'Postgres' mientras extrae.${NC}"
    
    # Configurar timeout de Docker Compose para redes lentas o inestables
    export COMPOSE_HTTP_TIMEOUT=300
    export DOCKER_CLIENT_TIMEOUT=300

    for i in {1..5}; do
        echo -e "${BLUE}Intento $i de 5 para descargar imágenes...${NC}"
        # Intentamos descargar las imágenes una por una si falla el pull paralelo normal
        if [ $i -gt 1 ]; then
            echo -e "${YELLOW}Limitando descargas paralelas para mejorar estabilidad...${NC}"
            if docker compose pull --parallel 1; then
                break
            fi
        else
            if docker compose pull; then
                break
            fi
        fi
        
        if [ $i -eq 5 ]; then
            echo -e "${RED}Error crítico: No se pudieron descargar las imágenes después de 5 intentos.${NC}"
            echo -e "${YELLOW}Sugerencia: Revisa tu conexión a internet o intenta ejecutar 'docker compose pull' manualmente en 'supabase/docker'.${NC}"
            exit 1
        fi
        
        WAIT_TIME=$((i * 10))
        echo -e "${YELLOW}Conexión reseteada o error de red. Reintentando en $WAIT_TIME segundos...${NC}"
        sleep $WAIT_TIME
    done
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
echo -e "${GREEN}[4/5] Preparando entorno de construcción...${NC}"

# Limpiar procesos de Node anteriores que puedan estar bloqueando memoria o puertos
echo -e "${BLUE}Limpiando procesos previos...${NC}"
pkill -f "next-router-worker" || true
pkill -f "next-render-worker" || true
pkill -f "next" || true

# Limpiar cache y builds anteriores para asegurar una instalación limpia
echo -e "${BLUE}Limpiando archivos temporales y dependencias...${NC}"
rm -rf .next
rm -rf node_modules
rm -f package-lock.json

if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm no está instalado. Intentando reinstalar dependencias base...${NC}"
    install_base_deps
fi

if command -v npm &> /dev/null; then
    npm cache clean --force
    echo -e "${BLUE}Instalando dependencias...${NC}"
    npm install
else
    echo -e "${RED}Error crítico: No se pudo encontrar npm después del intento de instalación.${NC}"
    exit 1
fi

# Solución para "JavaScript heap out of memory"
# Asignar memoria a Node de forma dinámica basada en la RAM disponible
export NODE_OPTIONS="--max-old-space-size=$NODE_MEM"

# Forzar el build y capturar errores (Configurado para ignorar errores de TS/Lint en next.config.ts)
if ! command -v npx &> /dev/null; then
    echo -e "${RED}Error: npx no está disponible. No se puede realizar el build.${NC}"
    exit 1
fi

if ! NEXT_DISABLE_SOURCEMAPS=1 NEXT_TELEMETRY_DISABLED=1 npx next build; then
    echo -e "${RED}Error: El build de Next.js falló.${NC}"
    echo -e "${YELLOW}Esto puede ser por falta de RAM (mínimo 2GB) o por un error en el código.${NC}"
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
    
    read -p "Presiona Enter para volver al menú..."
}

# --- MENÚ PRINCIPAL ---

while true; do
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
    echo -e "${GREEN}      M E N Ú   D E   G E S T I Ó N   (Vett3x)       ${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo -e "1) 🚀 Instalar / Actualizar todo (Panel + Supabase)"
    echo -e "2) 🔑 Ver Credenciales de Supabase (DB/Keys)"
    echo -e "3) 📦 Realizar Backup (Panel + DB)"
    echo -e "4) 📋 Ver Logs de Supabase"
    echo -e "5) 🛠️ Cambiar Contraseña del Panel"
    echo -e "6) 🧨 REINSTALAR TODO (Borra Datos)"
    echo -e "7) ❌ Salir"
    echo -e "${BLUE}---------------------------------------------------${NC}"
    read -p "Selecciona una opción [1-7]: " OPTION

    case $OPTION in
        1) run_install ;;
        2) show_credentials ;;
        3) run_backup ;;
        4) show_logs ;;
        5) 
            read -p "Nuevo Email: " NEW_EMAIL
            read -s -p "Nueva Contraseña: " NEW_PASS
            echo ""
            supabase-auth-passwd "$NEW_EMAIL" "$NEW_PASS"
            read -p "Presiona Enter para volver..."
            ;;
        6) full_reinstall ;;
        7) exit 0 ;;
        *) echo -e "${RED}Opción no válida${NC}" ; sleep 2 ;;
    esac
done
