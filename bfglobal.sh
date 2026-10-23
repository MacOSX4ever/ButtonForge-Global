#!/usr/bin/env bash
# WoW Addon Isolation - ButtonForge → ButtonForgeGlobal
# FIXED VERSION: Adds BFEventFrames and BUTTONFORGE_FLYOUT_BUTTON renaming
# Last ButtonForge version tested 1.3.4.2. Should be future-proof.

export LC_CTYPE=UTF-8
set -e

R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
N='\033[0m'

log_success() { echo -e "${G}✓${N} $1"; }
log_info()    { echo -e "${B}[INFO]${N} $1"; }

# Detect OS and set default addon path

# macOS detection
if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS_DEFAULT_SYSTEM="/Applications/World of Warcraft/_retail_/Interface/AddOns/ButtonForge"
    MACOS_DEFAULT_USER="$HOME/Library/Application Support/Blizzard/World of Warcraft/_retail_/Interface/AddOns/ButtonForge"

    if [ -d "$MACOS_DEFAULT_SYSTEM" ]; then
        SRC_DIR="$MACOS_DEFAULT_SYSTEM"
        log_info "Found ButtonForge at macOS Applications folder: $SRC_DIR"
    elif [ -d "$MACOS_DEFAULT_USER" ]; then
        SRC_DIR="$MACOS_DEFAULT_USER"
        log_info "Found ButtonForge at macOS user Library location: $SRC_DIR"
    fi
fi

# WSL vs Git Bash / MSYS
if [ -z "$SRC_DIR" ]; then
    WINDOWS_DEFAULT="$HOME/Documents/World of Warcraft/_retail_/Interface/AddOns/ButtonForge"

    # Detect WSL
    if grep -q Microsoft /proc/version 2>/dev/null; then
        WIN_USER=$(cmd.exe /C "echo %USERNAME%" | tr -d '\r')
        WINDOWS_DEFAULT="/mnt/c/Users/$WIN_USER/Documents/World of Warcraft/_retail_/Interface/AddOns/ButtonForge"
        ENV_NAME="WSL"
    else
        # Git Bash / MSYS2
        WINDOWS_DEFAULT="$HOME/Documents/World of Warcraft/_retail_/Interface/AddOns/ButtonForge"
        ENV_NAME="Git Bash/MSYS"
    fi

    if [ -d "$WINDOWS_DEFAULT" ]; then
        SRC_DIR="$WINDOWS_DEFAULT"
        log_info "Found ButtonForge at Windows default location ($ENV_NAME): $SRC_DIR"
    fi
fi

# Fallback to user-provided path if no default found
if [ -z "$SRC_DIR" ]; then
    if [ -z "$1" ]; then
        echo -e "${R}Error:${N} Could not find ButtonForge in default locations. Please provide path:"
        echo -e "${G}Usage:${N} $0 /path/to/ButtonForge"
        exit 1
    fi

    if [ ! -d "$1" ]; then
        echo -e "${R}Error:${N} Provided directory does not exist: $1"
        exit 1
    fi

    SRC_DIR="$1"
    log_info "Using user-provided path: $SRC_DIR"
fi

if ! command -v perl >/dev/null 2>&1; then
    echo -e "${R}Error:${N} Perl is required to process the addon files."
    exit 1
fi

BASE_NAME=$(basename "$SRC_DIR")
PARENT_DIR=$(dirname "$SRC_DIR")
DEST_DIR="$PARENT_DIR/${BASE_NAME}Global"

log_info "Source: $SRC_DIR"
log_info "Destination: $DEST_DIR"

echo ""
echo -e "${G}WoW Addon Isolation:${N} $BASE_NAME → ${BASE_NAME}Global"
echo ""

# STEP 1: Clone
log_info "STEP 1/5: Cloning..."
rm -rf "$DEST_DIR"
cp -R "$SRC_DIR" "$DEST_DIR"
log_success "Cloned"
echo ""

# STEP 2: Rename files FIRST (before TOC processing)
log_info "STEP 2/5: Renaming files..."
[ -f "$DEST_DIR/ButtonForge_API1.lua" ] && mv "$DEST_DIR/ButtonForge_API1.lua" "$DEST_DIR/ButtonForgeGlobal_API1.lua"
[ -f "$DEST_DIR/ButtonForge.blp" ] && mv "$DEST_DIR/ButtonForge.blp" "$DEST_DIR/ButtonForgeGlobal.blp"
log_success "Files renamed"
echo ""

# STEP 3: Process TOC
log_info "STEP 3/5: Processing TOC..."
SRC_TOC="$BASE_NAME.toc"
DEST_TOC="${BASE_NAME}Global.toc"

cp "$DEST_DIR/$SRC_TOC" "$DEST_DIR/${SRC_TOC}.bak"
perl -0777 -pe 's/(\r?\n)## SavedVariablesPerCharacter: /, /g' "$DEST_DIR/$SRC_TOC" > "$DEST_DIR/$DEST_TOC"

# Apply replacements
perl -i -pe '
s/^## Title: ButtonForge/## Title: Button Forge Global/;
s/ButtonForgeSave/ButtonForgeGlobal_Save/g;
s/ButtonForgeGlobalSettings/ButtonForgeGlobal_Settings/g;
s/ButtonForgeGlobalProfiles/ButtonForgeGlobal_Profiles/g;
s/ButtonForgeGlobalBackup/ButtonForgeGlobal_Backup/g;
s/BFSave/BFGSave/g;
s/BF_/BFG_/g;
s/ButtonForge_API1.lua/ButtonForgeGlobal_API1.lua/g;
s/ButtonForge.blp/ButtonForgeGlobal.blp/g;
s/ButtonForge\//ButtonForgeGlobal\//g;
' "$DEST_DIR/$DEST_TOC"

rm "$DEST_DIR/$SRC_TOC"
log_success "TOC processed"
echo ""

# STEP 4: Add visual distinction (dark green background for Global version)
log_info "STEP 4/5: Adding visual distinction..."
if [ -f "$DEST_DIR/Const.lua" ]; then
    # Change BarBackdrop color to dark green (almost black) for Global version
    perl -i -pe 's/Const\.BarBackdrop\s*=\s*\{0\.1, 0\.1, 0\.4, 0\.85\}/Const.BarBackdrop = {0.05, 0.12, 0.05, 0.85}/' "$DEST_DIR/Const.lua"
fi
log_success "Visual distinction added (dark green background)"
echo ""

log_info "STEP 5/5: Processing all text files..."

find "$DEST_DIR" -type f ! -path "*/Images/*" ! -name "*.tga" ! -name "*.blp" ! -name "*.bak" -print0 | while IFS= read -r -d '' file; do
    # Skip binary files
    if file "$file" 2>/dev/null | grep -q "text\|empty"; then
        perl -i -pe '
    # Saved Variables
    s/ButtonForgeSave/ButtonForgeGlobal_Save/g;
    s/ButtonForgeGlobalSettings/ButtonForgeGlobal_Settings/g;
    s/ButtonForgeGlobalProfiles/ButtonForgeGlobal_Profiles/g;
    s/ButtonForgeGlobalBackup/ButtonForgeGlobal_Backup/g;
    s/BFSave\b/BFGSave/g;

    # Event Frames table (global collision fix - must rename so both addons have isolated tables)
    s/\bBFEventFrames\b/BFGEventFrames/g;

    # Flyout button frame name string (global _G collision fix)
    s/"BUTTONFORGE_FLYOUT_BUTTON"/"BUTTONFORGEGLOBAL_FLYOUT_BUTTON"/g;
    
    # Global Tables
    s/\bBFLocales\b/BFGLocales/g;
    s/\bBFConst\b/BFGConst/g;
    s/\bBFUtil\b/BFGUtil/g;
    s/\bBFUILib\b/BFGUILib/g;
    s/\bBFButton\b/BFGButton/g;
    s/\bBFBar\b/BFGBar/g;
    s/\bBFCustomAction\b/BFGCustomAction/g;
    s/\bBFKeyBinder\b/BFGKeyBinder/g;
    s/ButtonForge_API1/ButtonForgeGlobal_API1/g;
    
    # Local variable assignments
    s/local Button = BFButton/local Button = BFGButton/g;
    s/local Bar = BFBar/local Bar = BFGBar/g;
    s/local Const = BFConst/local Const = BFGConst/g;
    s/local Util = BFUtil/local Util = BFGUtil/g;
    s/local UILib = BFUILib/local UILib = BFGUILib/g;
    s/local Locales = BFLocales/local Locales = BFGLocales/g;
    s/local KeyBinder = BFKeyBinder/local KeyBinder = BFGKeyBinder/g;
    
    # Frame Names
    s/ButtonForge_SpellFlyout/ButtonForgeGlobal_SpellFlyout/g;
    s/BFBindingMode/BFGBindingMode/g;
    s/BFBindingOverlay/BFGBindingOverlay/g;
    s/BFBindingDialog/BFGBindingDialog/g;
    s/BFOverlay\b/BFGOverlay/g;
    s/BFConfigureLayer/BFGConfigureLayer/g;
    s/BFAdvancedToolsLayer/BFGAdvancedToolsLayer/g;
    s/BFCreateBarOverlay/BFGCreateBarOverlay/g;
    s/BFDestroyBarOverlay/BFGDestroyBarOverlay/g;
    s/BFIconDragOverlay/BFGIconDragOverlay/g;
    
    # Toolbar
    s/BFToolbar\b/BFGToolbar/g;
    s/BFToolbarToggle/BFGToolbarToggle/g;
    s/BFToolbarCreateBar/BFGToolbarCreateBar/g;
    s/BFToolbarCreateBonusBar/BFGToolbarCreateBonusBar/g;
    s/BFToolbarDestroyBar/BFGToolbarDestroyBar/g;
    s/BFToolbarAdvanced/BFGToolbarAdvanced/g;
    s/BFToolbarRightClickSelfCast/BFGToolbarRightClickSelfCast/g;
    
    # Bindings
    s/BINDING_HEADER_ButtonForge/BINDING_HEADER_ButtonForgeGlobal/g;
    s/CLICK BFToolbar/CLICK BFGToolbar/g;
    s/\/click BFToolbar/\/click BFGToolbar/g;
    
    # Slash Commands - exact quoted matches only
    s|/buttonforge|/buttonforgeglobal|g;
    s|/bufo|/bufog|g;
    
    # Slash command handler functions
	s/ButtonForge_OnSlashCmd/ButtonForgeGlobal_OnSlashCmd/g;
	s/BF_OnSlashCmd/BFG_OnSlashCmd/g;
	s/slash_buttonforge/slash_buttonforgeglobal/g;
	s/slash_bufo/slash_bufog/g;
    
    s/SlashCmdList\["BUTTONFORGE"\]/SlashCmdList["BUTTONFORGEGLOBAL"]/g;
	s/SLASH_BUTTONFORGE/SLASH_BUTTONFORGEGLOBAL/g;
    
    # Paths
    s/ButtonForge\//ButtonForgeGlobal\//g;
    s/ButtonForge\\\\/ButtonForgeGlobal\\\\/g;
    s/Addons\\\\ButtonForge\\\\Images/Addons\\\\ButtonForgeGlobal\\\\Images/g;
    
    # Display names
    s/Button Forge(?! Global)/Button Forge Global/g;
    s/ButtonForge(?!Global)/ButtonForgeGlobal/g;
    ' "$file"
    fi
done

log_success "Content processed"
echo ""

# STEP 6a: Fix dead MAX_ACCOUNT_MACROS global (Blizzard removed this FrameXML
# constant in a recent client patch). RefreshMacro() in Button.lua still reads
# it as a bare global, which is now nil, causing:
#   "attempt to perform arithmetic on global 'MAX_ACCOUNT_MACROS' (a nil value)"
# The addon already defines its own copy as Const.MAX_ACCOUNT_MACROS (Const.lua),
# and Button.lua already has 'local Const = BFConst' in scope, so point the
# bare-global reads at Const.MAX_ACCOUNT_MACROS instead. This also affects
# stock ButtonForge, not just isolation - fixed here so the Global copy works
# regardless of upstream.
log_info "STEP 6a: Patching dead MAX_ACCOUNT_MACROS global in Button.lua..."
if [ -f "$DEST_DIR/Button.lua" ]; then
    perl -i -pe 's/(?<!Const\.)\bMAX_ACCOUNT_MACROS\b/Const.MAX_ACCOUNT_MACROS/g' "$DEST_DIR/Button.lua"
    log_success "MAX_ACCOUNT_MACROS references now use Const.MAX_ACCOUNT_MACROS"
else
    echo -e "${Y}[WARN]${N} Button.lua not found, skipping MAX_ACCOUNT_MACROS patch"
fi
echo ""

# STEP 6b: Nil-guard C_AssistedCombat calls in Button.lua
# On a new character, GetNextCastSpell() and GetActionSpell() both return nil before
# the combat system initialises. Two functions pass that nil into C_Spell/GameTooltip
# which crashes. Patch both with early-return guards.
log_info "STEP 6/6: Patching nil guards for C_AssistedCombat in Button.lua..."
if [ -f "$DEST_DIR/Button.lua" ]; then
    perl -i -0777 -pe '
    # Fix 1: UpdateTextureSpellSingleButtonAssistant
    # GetActionSpell() fallback also returns nil on new characters
    s/if spellID == nil then\r?\n\t\tlocal texture = C_Spell\.GetSpellTexture\(C_AssistedCombat\.GetActionSpell\(\)\);\r?\n\t\tself\.WIcon:SetTexture\(texture\);\r?\n\t\treturn;\r?\n\tend/if spellID == nil then\n\t\tlocal actionSpell = C_AssistedCombat.GetActionSpell();\n\t\tif actionSpell == nil then return; end\n\t\tlocal texture = C_Spell.GetSpellTexture(actionSpell);\n\t\tself.WIcon:SetTexture(texture);\n\t\treturn;\n\tend/g;

    # Fix 2: UpdateTooltipSpellSingleButtonAssistant
    # GetActionSpell() fallback also returns nil, then SetSpellByID(nil) crashes
    s/if spellID == nil then\r?\n\t\tspellID = C_AssistedCombat\.GetActionSpell\(\);\r?\n\tend\r?\n\r?\n\tGameTooltip:SetSpellByID\(spellID, false, true\);/if spellID == nil then\n\t\tspellID = C_AssistedCombat.GetActionSpell();\n\tend\n\tif spellID == nil then return; end\n\n\tGameTooltip:SetSpellByID(spellID, false, true);/g;
    ' "$DEST_DIR/Button.lua"
    log_success "Nil guards patched (UpdateTextureSpellSingleButtonAssistant, UpdateTooltipSpellSingleButtonAssistant)"
else
    echo -e "${Y}[WARN]${N} Button.lua not found, skipping nil guard patch"
fi
echo ""

log_success "ButtonForge → ButtonForgeGlobal conversion complete!"
echo ""
echo -e "${G}The Global version is now ready to use alongside the original ButtonForge addon.${N}"
