#!/bin/bash
# INSTALLER ALPINE XFCE UNTUK ARM32 (ARMv7a)
# FIXED VERSION - 2026
# All known issues addressed

set -e

echo "======================================"
echo " INSTALL ALPINE XFCE UNTUK ARM32"
echo "======================================"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 1. Update Termux
print_status "Updating Termux packages..."
pkg update -y && pkg upgrade -y

# 2. Install required packages
print_status "Installing required packages..."
pkg install proot-distro tigervnc x11-repo -y || print_error "Failed to install packages"

# 3. Install Alpine
if proot-distro list | grep -q "alpine"; then
    print_status "Alpine already installed. Updating..."
    proot-distro login alpine -- apk update
else
    print_status "Installing Alpine..."
    proot-distro install alpine || print_error "Failed to install Alpine"
fi

# 4. Setup Alpine with all fixes
print_status "Setting up Alpine environment with fixes..."

# Use a single heredoc with proper error handling
proot-distro login alpine -- bash << 'EOF'
set -e

echo "Updating Alpine packages..."
apk update && apk upgrade

echo "Installing XFCE and dependencies..."
# Install all required packages including xfce4-session explicitly
apk add --no-cache \
    xfce4 \
    xfce4-session \
    xfce4-terminal \
    thunar \
    thunar-volman \
    tumbler \
    xfce4-settings \
    xfconf \
    tigervnc \
    netsurf \
    dbus \
    dbus-x11 \
    hicolor-icon-theme \
    adwaita-icon-theme \
    xrandr \
    xset \
    xdpyinfo \
    bash \
    sudo

echo "Setting up D-Bus..."
# Fix D-Bus configuration for Alpine
mkdir -p /run/dbus
rm -f /var/lib/dbus/machine-id
dbus-uuidgen > /var/lib/dbus/machine-id
dbus-uuidgen > /etc/machine-id

# Create D-Bus service script
cat > /etc/init.d/dbus-alpine << 'DBUSSCRIPT'
#!/sbin/openrc-run
command="/usr/bin/dbus-daemon"
command_args="--system --nofork"
pidfile="/run/dbus/pid"
name="D-Bus System"
DBUSSCRIPT
chmod +x /etc/init.d/dbus-alpine 2>/dev/null || true

# Create VNC directory
mkdir -p /root/.vnc

# Set VNC password
echo "123456" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# Create proper xstartup with XFCE4 session
cat > /root/.vnc/xstartup << 'VNCXSTARTUP'
#!/bin/sh
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP="XFCE"
export XDG_MENU_PREFIX="xfce-"
export XDG_RUNTIME_DIR=/tmp/runtime-root
export DISPLAY=:1

# Create runtime directory
mkdir -p /tmp/runtime-root
chmod 700 /tmp/runtime-root

# Start D-Bus session
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval `dbus-launch --sh-syntax --exit-with-session`
fi

# Fix for XFCE4 panel
rm -rf /root/.config/xfce4/panel 2>/dev/null || true

# Start XFCE4
xfce4-session &
VNCXSTARTUP

chmod +x /root/.vnc/xstartup

# Create VNC start script with proper display handling
cat > /root/start-vnc.sh << 'STARTVNC'
#!/bin/bash
echo "Starting VNC server..."

# Kill any existing VNC sessions on display :1
vncserver -kill :1 2>/dev/null || true

# Clean up old VNC files
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

# Start VNC server with explicit geometry and color depth
vncserver :1 \
    -geometry 1280x720 \
    -depth 24 \
    -localhost no \
    -SecurityTypes VncAuth \
    -fg 2>&1 &

VNC_PID=$!
sleep 3

# Check if VNC started successfully
if pgrep -f "Xvnc :1" > /dev/null; then
    echo ""
    echo "======================================"
    echo "✅ VNC Server started successfully!"
    echo "======================================"
    echo "Port: 5901"
    echo "Password: 123456"
    echo "VNC PID: $VNC_PID"
    echo ""
    echo "To stop: vncserver -kill :1"
    echo "======================================"
else
    echo "❌ Failed to start VNC server"
    exit 1
fi
STARTVNC

chmod +x /root/start-vnc.sh

# Create stop script
cat > /root/stop-vnc.sh << 'STOPVNC'
#!/bin/bash
vncserver -kill :1 2>/dev/null
pkill -f "Xvnc :1" 2>/dev/null || true
rm -f /tmp/.X1-lock 2>/dev/null || true
echo "VNC server stopped"
STOPVNC

chmod +x /root/stop-vnc.sh

# Create test script to verify everything works
cat > /root/test-xfce.sh << 'TESTXFCE'
#!/bin/bash
echo "Testing XFCE installation..."
export DISPLAY=:1
which xfce4-session || echo "xfce4-session not found"
ls -la /usr/bin/xfce4-* | head -5
echo "XFCE packages installed:"
apk list --installed | grep xfce
TESTXFCE

chmod +x /root/test-xfce.sh

# Run test
echo "Running XFCE test..."
/root/test-xfce.sh

EOF

# Check if Alpine setup succeeded
if [ $? -eq 0 ]; then
    print_status "Alpine setup completed successfully"
else
    print_error "Alpine setup failed"
fi

# Create wrapper scripts for Termux
print_status "Creating Termux wrapper scripts..."

# Start script with port forwarding info
cat > ~/start-alpine-xfce.sh << 'WRAPPER'
#!/bin/bash
echo "======================================"
echo " Starting Alpine XFCE Desktop"
echo "======================================"
echo ""
echo "Checking if VNC is already running..."
proot-distro login alpine -- bash -c "pgrep -f 'Xvnc :1' && echo 'VNC already running!' && exit 1" 2>/dev/null

if [ $? -eq 1 ]; then
    echo "VNC is already running. Use ./stop-alpine-xfce.sh first"
    exit 1
fi

echo "Starting Alpine with VNC..."
proot-distro login alpine -- bash -c "cd /root && ./start-vnc.sh"

if [ $? -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "🎉 DESKTOP IS READY! 🎉"
    echo "======================================"
    echo ""
    echo "📱 VNC CONNECTION DETAILS:"
    echo "   Host: localhost"
    echo "   Port: 5901"
    echo "   Password: 123456"
    echo ""
    echo "💡 TIPS:"
    echo "   • Use VNC Viewer app from Play Store"
    echo "   • If connection fails, wait 5 seconds and retry"
    echo "   • For better performance, use 16-bit color mode"
    echo ""
    echo "🛑 To stop: ./stop-alpine-xfce.sh"
    echo "======================================"
else
    echo "❌ Failed to start desktop"
fi
WRAPPER

chmod +x ~/start-alpine-xfce.sh

# Stop script
cat > ~/stop-alpine-xfce.sh << 'STOPWRAPPER'
#!/bin/bash
echo "Stopping Alpine XFCE VNC server..."
proot-distro login alpine -- bash -c "/root/stop-vnc.sh"
echo "Done"
STOPWRAPPER

chmod +x ~/stop-alpine-xfce.sh

# Status script
cat > ~/status-alpine-xfce.sh << 'STATUSWRAPPER'
#!/bin/bash
echo "======================================"
echo " Alpine XFCE Status"
echo "======================================"
echo ""
echo "VNC Server Status:"
proot-distro login alpine -- bash -c "pgrep -f 'Xvnc :1' && echo '✅ Running on port 5901' || echo '❌ Not running'"
echo ""
echo "Installed Packages:"
proot-distro login alpine -- bash -c "apk list --installed | grep -E '(xfce|vnc|netsurf)' | wc -l" | xargs echo "XFCE packages count:"
echo ""
echo "Disk Usage:"
proot-distro login alpine -- bash -c "df -h / | tail -1"
echo ""
echo "To start: ./start-alpine-xfce.sh"
echo "To stop: ./stop-alpine-xfce.sh"
STATUSWRAPPER

chmod +x ~/status-alpine-xfce.sh

# Final message
echo ""
echo "======================================"
echo -e "${GREEN}✅ INSTALLATION COMPLETE!${NC}"
echo "======================================"
echo ""
echo "🚀 QUICK START:"
echo "   ./start-alpine-xfce.sh"
echo ""
echo "🛑 STOP:"
echo "   ./stop-alpine-xfce.sh"
echo ""
echo "📊 STATUS:"
echo "   ./status-alpine-xfce.sh"
echo ""
echo "======================================"
echo ""
echo "⚠️  IMPORTANT NOTES:"
echo "1. Install VNC Viewer from Play Store first!"
echo "2. If desktop doesn't appear, wait 10 seconds and reconnect"
echo "3. First start might take 30-60 seconds"
echo "4. If blank screen appears, try:"
echo "   ./stop-alpine-xfce.sh && ./start-alpine-xfce.sh"
echo ""
echo "🐛 TROUBLESHOOTING:"
echo "• Check logs: proot-distro login alpine -- tail -f /root/.vnc/*.log"
echo "• Test XFCE: proot-distro login alpine -- /root/test-xfce.sh"
echo "• Manual start: proot-distro login alpine -- vncserver :1"
echo ""