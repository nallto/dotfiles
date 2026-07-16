#!/usr/bin/env bash
# Claude Code statusLine.
# Segments (L->R): model, mode(effort/thinking/fast), context%, 5h rate, 1W rate.

input=$(cat)

# ── Powerline glyphs (Nerd Font) ─────────────────────────────────────────────
CAP_L=$''   #  left rounded cap
CAP_R=$''   #  right rounded cap
ESC=$'\033'

# ── Fixed colors (truecolor "R;G;B") ─────────────────────────────────────────
FG_BLACK="10;10;10"       # text on light (gradient) backgrounds
FG_WHITE="240;240;240"    # text on the darkest (alarm) gradient background
FG_LIGHT="224;224;224"    # #E0E0E0 — text on the dark bg (model/mode)
FG_DIM="120;126;138"      # dimmed text for OFF states
BG_DARK="51;54;62"        # #33363E — neutral dark gray; model/mode pills (visible on dark term)

# ── Usage-gradient palette (by tier) + subdued in-pill text ───────────────────
BG_ALARM="200;30;40"            # >=95%  (bold, white text)
BG_RED_HI="224;85;95"           # >=90%  (bold)
BG_RED="240;128;140"            # >=80%
BG_YELLOW="225;193;85"          # >=50%
BG_GREEN="126;196;157"          # <50%
FG_SUBDUED_DARK="48;50;54"      # reset-time / suffix on a light gradient bg
FG_SUBDUED_LIGHT="235;205;205"  # reset-time / suffix on the alarm bg

# ── Segment icons (Nerd Font glyphs) ─────────────────────────────────────────
ICON_MODEL=$''
ICON_CONTEXT=$''
ICON_5H=$''
ICON_1W=$''
ICON_EFFORT=$''
ICON_THINK=$''
ICON_FAST=$'⚡'
ICON_SEPARATOR=$''

# ── Helper: map integer usage% → "bgR;G;B|bold(0/1)|fgR;G;B" ─────────────────
usage_style() {
    local p=$1
    if   (( p >= 95 )); then printf '%s|1|%s' "$BG_ALARM"  "$FG_WHITE"   # dark red, bold, white text
    elif (( p >= 90 )); then printf '%s|1|%s' "$BG_RED_HI" "$FG_BLACK"   # strong red, bold
    elif (( p >= 80 )); then printf '%s|0|%s' "$BG_RED"    "$FG_BLACK"   # red
    elif (( p >= 50 )); then printf '%s|0|%s' "$BG_YELLOW" "$FG_BLACK"   # yellow
    else                     printf '%s|0|%s' "$BG_GREEN"  "$FG_BLACK"   # green
    fi
}

# ── Helper: format Unix epoch as local absolute time ─────────────────────────
# "HH:MM" (same day) | "Thu HH:MM" (other day, weekday — resets are always <=7d out) | "" (past/missing)
format_reset_time() {
    local epoch=$1
    [[ -z "$epoch" ]] && return 0
    local now; now=$(date +%s)
    (( epoch <= now )) && return 0
    local reset_date today
    reset_date=$(date -r "$epoch" "+%Y%m%d" 2>/dev/null) \
        || reset_date=$(date -d "@$epoch" "+%Y%m%d" 2>/dev/null) \
        || return 0
    today=$(date "+%Y%m%d")
    if [[ "$reset_date" == "$today" ]]; then
        date -r "$epoch" "+%H:%M" 2>/dev/null || date -d "@$epoch" "+%H:%M" 2>/dev/null
    else
        LC_ALL=C date -r "$epoch" "+%a %H:%M" 2>/dev/null || LC_ALL=C date -d "@$epoch" "+%a %H:%M" 2>/dev/null
    fi
}

# ── Helper: shorten Claude model display name ────────────────────────────────
# "Claude Opus 4.7 (1M context)" → "Opus 4.7 1M" ; "Claude Sonnet 4.6" → "Sonnet 4.6"
shorten_model() {
    local name="$1"
    name="${name#Claude }"
    printf '%s' "$name" | sed -E 's/ \(([0-9]+[kKmMbBgG]) context\)/ \1/'
}

# ── Parse JSON input ─────────────────────────────────────────────────────────
model_display=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
effort_level=$(printf '%s'  "$input" | jq -r '.effort.level // empty')
thinking_on=$(printf '%s'   "$input" | jq -r '.thinking.enabled')   # true|false|null ( // empty would drop false! )
fast_on=$(printf '%s'       "$input" | jq -r '.fast_mode')          # true|false|null
ctx_pct_raw=$(printf '%s'   "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(printf '%s'      "$input" | jq -r '.context_window.context_window_size // empty')
five_pct_raw=$(printf '%s'  "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(printf '%s'    "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct_raw=$(printf '%s'  "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(printf '%s'    "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ── Build the segment list (parallel arrays) ─────────────────────────────────
seg_bg=(); seg_fg=(); seg_bold=(); seg_txt=()
add_seg() { seg_bg+=("$1"); seg_fg+=("$2"); seg_bold+=("$3"); seg_txt+=("$4"); }

# Segment: model — dark git bg, light text
if [[ -n "$model_display" ]]; then
    add_seg "$BG_DARK" "$FG_LIGHT" 0 "${ICON_MODEL}  $(shorten_model "$model_display")"
fi

# Segment: mode — effort level + thinking on/off + fast on/off (OFF is dimmed)
mode_txt=""
[[ -n "$effort_level" ]] && mode_txt="${ICON_EFFORT}  $effort_level"
if   [[ "$thinking_on" == "true"  ]]; then mode_txt+=" ${ICON_SEPARATOR} ${ICON_THINK}  on"
elif [[ "$thinking_on" == "false" ]]; then mode_txt+=" ${ICON_SEPARATOR} ${ICON_THINK}  ${ESC}[38;2;${FG_DIM}moff${ESC}[38;2;${FG_LIGHT}m"
fi
if   [[ "$fast_on" == "true"  ]]; then mode_txt+=" ${ICON_SEPARATOR} ${ICON_FAST} on"
elif [[ "$fast_on" == "false" ]]; then mode_txt+=" ${ICON_SEPARATOR} ${ICON_FAST} ${ESC}[38;2;${FG_DIM}moff${ESC}[38;2;${FG_LIGHT}m"
fi
[[ -n "$mode_txt" ]] && add_seg "$BG_DARK" "$FG_LIGHT" 0 "$mode_txt"

# Helper: build a gradient segment (context / 5h / 1W). $3 = reset epoch (opt).
add_gradient_seg() {
    local icon="$1" raw="$2" reset="$3" suffix="$4"
    local pct; pct=$(printf "%.0f" "$raw")
    local g_bg g_bold g_fg
    IFS='|' read -r g_bg g_bold g_fg <<< "$(usage_style "$pct")"
    local subdued="$FG_SUBDUED_DARK"                           # subdued dark on light bg
    [[ "$g_fg" == "$FG_WHITE" ]] && subdued="$FG_SUBDUED_LIGHT" # subdued light on alarm bg
    local txt="${icon}  ${pct}%"
    if [[ -n "$reset" ]]; then
        local t; t=$(format_reset_time "$reset")
        [[ -n "$t" ]] && txt+=" ${ICON_SEPARATOR} ${ESC}[38;2;${subdued}m${t}${ESC}[38;2;${g_fg}m"
    fi
    [[ -n "$suffix" ]] && txt+=" ${ICON_SEPARATOR} ${ESC}[38;2;${subdued}m${suffix}${ESC}[38;2;${g_fg}m"
    add_seg "$g_bg" "$g_fg" "$g_bold" "$txt"
}

# Format the max context size for the context pill: 1000000 -> 1M, 200000 -> 200k
ctx_size_fmt=""
if [[ -n "$ctx_size" ]]; then
    if   (( ctx_size >= 1000000 )); then ctx_size_fmt="$(( ctx_size / 1000000 ))M"
    elif (( ctx_size >= 1000    )); then ctx_size_fmt="$(( ctx_size / 1000 ))k"
    else                                 ctx_size_fmt="$ctx_size"
    fi
fi

[[ -n "$ctx_pct_raw"  ]] && add_gradient_seg "$ICON_CONTEXT" "$ctx_pct_raw"  "" "$ctx_size_fmt"
[[ -n "$five_pct_raw" ]] && add_gradient_seg "$ICON_5H"  "$five_pct_raw" "$five_reset" ""
[[ -n "$week_pct_raw" ]] && add_gradient_seg "$ICON_1W"  "$week_pct_raw" "$week_reset" ""

# ── Render: each segment is its own rounded pill, spaced apart ───────────────
result=""
for i in "${!seg_txt[@]}"; do
    bg=${seg_bg[i]}; fg=${seg_fg[i]}; bold=${seg_bold[i]}; txt=${seg_txt[i]}
    bc=""; [[ "$bold" == "1" ]] && bc="1;"
    (( i > 0 )) && result+=" "                                    # gap between pills
    result+="${ESC}[38;2;${bg}m${CAP_L}"                          # left rounded cap
    result+="${ESC}[0m${ESC}[${bc}38;2;${fg};48;2;${bg}m ${txt} " # segment body
    result+="${ESC}[0m${ESC}[38;2;${bg}m${CAP_R}${ESC}[0m"        # right rounded cap
done

printf '%s\n' "$result"
