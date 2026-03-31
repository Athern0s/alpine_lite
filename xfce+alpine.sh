#!/bin/bash
# OPENBOX DESKTOP + TINT2 PANEL UNTUK ALPINE ARM32
# Architect 03 - FULL FIX + PANEL VERSION

echo "======================================"
echo " OPENBOX + TINT2 DESKTOP - ARM32"
echo "======================================"

# 1. Bersihin semua sisa VNC
vncserver -kill :1 2>/dev/null
pkill Xvnc 2>/dev/null
pkill openbox 2>/dev/null
pkill tint2 2>/dev/null
rm -rf /tmp/.X1* /tmp/.X11-unix/X1 2>/dev/null
rm -rf ~/.vnc 2>/dev/null

# 2. Install Openbox + TINT2 + komponen lengkap
echo "📦 Installing Openbox + Tint2 panel..."
apk add --no-cache \
    openbox \
    xterm \
    tigervnc \
    xfce4-terminal \
    firefox-esr \
    htop \
    nano \
    alsa-utils \
    pulseaudio \
    dbus \
    xinit \
    tint2 \
    feh \
    lxappearance \
    xfce4-settings \
    xfce4-power-manager

# 3. Setup D-Bus (biar aplikasi gak error)
echo "🔧 Setting up D-Bus..."
mkdir -p /run/dbus
dbus-uuidgen > /var/lib/dbus/machine-id
dbus-daemon --system --fork 2>/dev/null

# 4. Buat folder config
mkdir -p ~/.config/openbox
mkdir -p ~/.config/tint2
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.themes
mkdir -p ~/.icons

# 5. Config TINT2 (taskbar kayak Windows)
echo "🎨 Configuring Tint2 panel..."
cat > ~/.config/tint2/tint2rc << 'EOF'
# Tint2 config - Windows-like taskbar
# Panel
panel_items = TSC
panel_size = 100% 30
panel_margin = 0 0
panel_padding = 2 0 2
panel_background_id = 1
wm_menu = 1
panel_dock = 0
panel_position = bottom center horizontal
panel_layer = top

# Font
font_shadow = 0
font = sans 10

# Background
rounded = 5
border_width = 1
background_color = #2c2c2c 100
border_color = #3c3c3c 100
background_id = 1

# Taskbar
taskbar_mode = multi_desktop
taskbar_padding = 2 2 2
taskbar_background_id = 0
taskbar_active_background_id = 0

# Tasks
task_icon = 1
task_text = 1
task_centered = 1
task_width = 150
task_padding = 6 2
task_font = sans 10
task_background_id = 2
task_active_background_id = 3
task_urgent_background_id = 4

# System tray
systray_padding = 2 0 2
systray_background_id = 0
systray_icon_size = 22

# Clock
time1_format = %H:%M
time1_font = sans 10 bold
clock_font = sans 10
clock_padding = 4 0
clock_background_id = 0

# Tooltip
tooltip_show_timeout = 0.5
tooltip_hide_timeout = 0.1
tooltip_padding = 4 2
tooltip_background_id = 1
tooltip_font = sans 10

# Background definitions
rounded = 5
border_width = 0
background_color = #2c2c2c 100
border_color = #2c2c2c 100
background_id = 0

rounded = 3
border_width = 1
background_color = #3c3c3c 100
border_color = #4c4c4c 100
background_id = 1

rounded = 3
border_width = 1
background_color = #404040 100
border_color = #505050 100
background_id = 2

rounded = 3
border_width = 1
background_color = #1e88e5 100
border_color = #0d47a1 100
background_id = 3

rounded = 3
border_width = 1
background_color = #e53935 100
border_color = #b71c1c 100
background_id = 4
EOF

# 6. Config OpenBox lengkap
echo "⚙️  Configuring Openbox..."
cat > ~/.config/openbox/rc.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config>
  <theme>
    <name>Clearlooks</name>
  </theme>
  <desktop>
    <desktops>1</desktops>
  </desktop>
  <mouse>
    <context name="Desktop">
      <mousebind button="Right" action="Click">
        <action name="ShowMenu">
          <menu>root-menu</menu>
        </action>
      </mousebind>
    </context>
  </mouse>
  <keyboard>
    <keybind key="W-t">
      <action name="Execute">
        <command>xfce4-terminal</command>
      </action>
    </keybind>
    <keybind key="W-f">
      <action name="Execute">
        <command>firefox</command>
      </action>
    </keybind>
    <keybind key="W-r">
      <action name="Reconfigure" />
    </keybind>
    <keybind key="W-q">
      <action name="Exit" />
    </keybind>
  </keyboard>
</openbox_config>
EOF

# 7. Autostart OpenBox dengan Tint2
cat > ~/.config/openbox/autostart << 'EOF'
# Openbox autostart dengan Tint2 panel

# Start Tint2 panel (taskbar)
tint2 &

# Start wallpaper (opsional)
# feh --bg-scale /usr/share/backgrounds/default.jpg &

# Start terminal di pojok
xfce4-terminal --geometry=80x24+0+0 &

# Start browser
# firefox &

# Power manager biar baterai awet
xfce4-power-manager &

# Set cursor tema (biar keliatan)
xsetroot -cursor_name left_ptr

# Set keyboard layout
setxkbmap -layout us
EOF

chmod +x ~/.config/openbox/autostart

# 8. Buat menu OpenBox
cat > ~/.config/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu>
  <menu id="root-menu" label="Menu">
    <item label="📁 Terminal">
      <action name="Execute">
        <command>xfce4-terminal</command>
      </action>
    </item>
    <item label="🌐 Browser (Firefox)">
      <action name="Execute">
        <command>firefox</command>
      </action>
    </item>
    <item label="📊 System Monitor">
      <action name="Execute">
        <command>htop</command>
      </action>
    </item>
    <separator />
    <item label="🎨 Appearance">
      <action name="Execute">
        <command>lxappearance</command>
      </action>
    </item>
    <separator />
    <item label="🔄 Restart Openbox">
      <action name="Reconfigure" />
    </item>
    <item label="⏻ Exit">
      <action name="Exit" />
    </item>
  </menu>
</openbox_menu>
EOF

# 9. Setup VNC dengan konfigurasi fix
echo "🖥️  Setting up VNC..."
mkdir -p ~/.vnc

# Password VNC
echo "123456" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Config VNC startup (Openbox + Tint2)
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/sh
# Fix dbus
export $(dbus-launch)

# Start Openbox
openbox --config-file ~/.config/openbox/rc.xml &

# Start Tint2 panel
sleep 1
tint2 -c ~/.config/tint2/tint2rc &

# Keep alive
while true; do
    sleep 10
done
EOF

chmod +x ~/.vnc/xstartup

# 10. Fix environment variables
echo "🔧 Fixing environment..."
cat >> ~/.profile << 'EOF'
export DISPLAY=:1
export PULSE_SERVER=tcp:127.0.0.1
export DBUS_SESSION_BUS_ADDRESS=""
EOF

# 11. D-Bus fix
cat >> ~/.bashrc << 'EOF'
# D-Bus auto start
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
fi
EOF

source ~/.bashrc

# 12. Start VNC
echo "🚀 Starting VNC..."
vncserver :1 -geometry 1024x768 -depth 16 -localhost no

echo ""
echo "======================================"
echo "✅ INSTALL SELESAI!"
echo "======================================"
echo ""
echo "📱 CARA AKSES:"
echo "1. Buka VNC Viewer di HP"
echo "2. Konek ke: localhost:1"
echo "3. Password: 123456"
echo ""
echo "🖱️  FITUR YANG SUDAH DITAMBAH:"
echo "✅ Tint2 Panel (taskbar kayak Windows)"
echo "✅ Menu OpenBox (klik kanan desktop)"
echo "✅ Shortcut keyboard:"
echo "   - Win + T : Terminal"
echo "   - Win + F : Firefox"
echo "   - Win + R : Restart Openbox"
echo "   - Win + Q : Exit"
echo ""
echo "📊 RAM USAGE: ~120-180 MB"
echo "======================================"