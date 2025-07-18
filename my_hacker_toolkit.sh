#!/bin/bash

# रंग और स्टाइल टेम्पलेट
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RESET='\033[0m'; BOLD='\033[1m'

show_banner() {
    echo -e "${CYAN}"
    echo "███████╗██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗██████╗     ████████╗ ██████╗  ██████╗ ██╗  ██╗██╗     ██╗  ██╗██╗████████╗";
    echo "╚══███╔╝██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗    ╚══██╔══╝██╔═══██╗██╔════╝ ██║  ██║██║     ██║ ██╔╝██║╚══██╔══╝";
    echo "  ███╔╝ ███████║███████║██║     █████╔╝ █████╗  ██████╔╝       ██║   ██║   ██║██║  ███╗███████║██║     █████╔╝ ██║   ██║   ";
    echo " ███╔╝  ██╔══██║██╔══██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗       ██║   ██║   ██║██║   ██║██╔══██║██║     ██╔═██╗ ██║   ██║   ";
    echo "███████╗██║  ██║██║  ██║╚██████╗██║  ██╗███████╗██║  ██║       ██║   ╚██████╔╝╚██████╔╝██║  ██║███████╗██║  ██╗██║   ██║   ";
    echo "╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝   ";
    echo -e "${GREEN}    Version: 0.1    ${RESET}"
}
generate_html_report() {
    read -p "स्कैन करने के लिए डायरेक्टरी (default: \$HOME): " target
    target="${target:-$HOME}"
    if [[ ! -d "$target" ]]; then
        echo -e "${RED}डायरेक्टरी नहीं मिली!${RESET}"
        return
    fi
    out="scan_report_$(basename "$target")_$(date +%Y%m%d_%H%M%S).html"
    echo "<html><head><title>Scan Report</title>
    <style>
      body{font-family:monospace;background:#1a1a1a;color:#c0ffc0;padding:20px}
      h1{color:#70db70}
      ul{margin-left:1em}
      pre{background:#222;padding:8px;border-radius:5px}
    </style>
    </head><body>
    <h1>Directory Scan: $target</h1>
    <h2>टाइम: $(date)</h2>
    <h2>Files & Folders:</h2>
    <pre>$(ls -lhA "$target")</pre>
    <h2>टोटल फाइल्स: $(find "$target" -type f | wc -l)</h2>
    <h2>टोटल डाइरेक्ट्री: $(find "$target" -type d | wc -l)</h2>
    <h2>बड़ी फाइल्स:</h2>
    <ul>" > "$out"

    find "$target" -type f -exec du -h {} + 2>/dev/null | sort -hr | head -5 | while read size file; do
        echo "<li>$file ($size)</li>" >> "$out"
    done
    echo "</ul>
    </body></html>" >> "$out"
    echo -e "${CYAN}रिपोर्ट बन गई: $out${RESET}"
}
monitor_directory() {
    echo "मॉनिटर के लिए डायरेक्टरी (default: \$HOME):"
    read target
    target="${target:-$HOME}"
    if [[ ! -d "$target" ]]; then
        echo -e "${RED}डायरेक्टरी गलत है!${RESET}"
        return
    fi
    echo -e "${GREEN}निगरानी शुरू: $target (Ctrl+C से रोकें)${RESET}"

    # Termux/Android: inotifywait (या pure bash fallback)
    if command -v inotifywait >/dev/null 2>&1; then
        inotifywait -m -r -e create,delete,modify,move "$target" --format '%T %w %e %f' --timefmt '%d-%m-%Y %H:%M' |
        while read ts path evt file; do
            echo -e "${YELLOW}[$ts] $path$file : $evt${RESET}"
            # टर्मक्स वॉयस-नोटिफिकेशन
            if command -v termux-tts-speak >/dev/null; then
                termux-tts-speak "Directory changed"
            fi
            if command -v termux-vibrate >/dev/null; then
                termux-vibrate -d 300
            fi
        done
    else
        # Pure Bash fallback (कम इवेंट वास्तविकता)
        prev="$(ls -lR "$target")"
        while true
        do
            sleep 3
            curr="$(ls -lR "$target")"
            if [[ "$curr" != "$prev" ]]; then
                echo -e "${YELLOW}[$(date)] बदलाव पाया गया${RESET}"
                prev="$curr"
            fi
        done
    fi
}
network_info() {
    echo -e "${CYAN}==== नेटवर्क जानकारी ====${RESET}"
    # आईपी, गेटवे, DNS, इफ कनेक्शन शो
    if command -v ip >/dev/null; then
        ip -4 addr show | grep inet
        echo -e "\nGateway:"
        ip route | grep default
    else
        ifconfig
    fi
    echo -e "\nActive नेटवर्क कनेक्शन (ss/netstat):"
    if command -v ss >/dev/null; then
        ss -tulpan
    else
        netstat -tulpan
    fi
}
ping_scan() {
    read -p "Host/IP डालें (default: 8.8.8.8): " target
    target="${target:-8.8.8.8}"
    echo -e "${YELLOW}पिंग टेस्ट $target ...${RESET}"
    ping -c 4 "$target"
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}इंटरनेट/नेटवर्क कनेक्शन OK${RESET}"
    else
        echo -e "${RED}नेटवर्क fail/timeout या unreachable${RESET}"
    fi
}
compare_files_folders() {
    echo -e "${CYAN}फाइल/FOLDER तुलना मॉड्यूल${RESET}"
    read -p "पहला फाइल/फोल्डर: " path1
    read -p "दूसरा फाइल/फोल्डर: " path2
    if [[ -d "$path1" && -d "$path2" ]]; then
        echo -e "${YELLOW}फोल्डर comparison (diff):${RESET}"
        diff -rq "$path1" "$path2"
        log_action "Folder diff $path1 vs $path2"
    elif [[ -f "$path1" && -f "$path2" ]]; then
        echo -e "${YELLOW}फाइल comparison (diff):${RESET}"
        diff -u "$path1" "$path2" | less
        log_action "File diff $path1 vs $path2"
    else
        echo -e "${RED}इनपुट सही नहीं। दोनों फाइल या दोनों फोल्डर दें!${RESET}"
    fi
}
find_duplicates() {
    read -p "किस डायरेक्टरी में डुप्लिकेट तलाशें?: " dir
    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}डायरेक्टरी नहीं मिली!${RESET}"; return
    fi
    echo -e "${CYAN}MD5 चेकसम से डुप्लिकेट फाइलें:${RESET}"
    find "$dir" -type f -exec md5sum {} + | sort | uniq -w32 -dD
    log_action "Duplicates searched in $dir"
}

main_menu() {
    echo -e "${YELLOW}[1] हैलो वर्ल्ड टूल"
    echo -e "${YELLOW}[2] डायरेक्टरी स्कैन + HTML रिपोर्ट${RESET}"
    echo -e "${YELLOW}[3] डायरेक्टरी मॉनिटरिंग (लाइव)${RESET}"
    echo -e "${YELLOW}[4] नेटवर्क इंफो${RESET}"
    echo -e "${YELLOW}[5] पिंग स्कैन और इंटरनेट टेस्ट${RESET}"
    echo -e "${YELLOW}[6] फाइल/फोल्डर तुलना (Diff)${RESET}"
echo -e "${YELLOW}[7] डुप्लिकेट फाइल फाइंडर${RESET}"
echo -e "[0] बाहर निकलें${RESET}"
    read -p "आपका विकल्प: " ch
    case $ch in
        1)
            echo -e "${GREEN}~ हेलो वर्ल्ड, टूलकिट शुरू!${RESET}"
            ;;
        2)
    generate_html_report
    read -p "जारी रखने के लिए Enter..." ;;
        3)
    monitor_directory
    read -p "जारी रखने के लिए Enter..." ;;
        4)
    network_info
    read -p "जारी रखने के लिए Enter..." ;;
5)
    ping_scan
    read -p "जारी रखने के लिए Enter..." ;;
6)
    compare_files_folders
    read -p "जारी रखने के लिए Enter..." ;;
7)
    find_duplicates
    read -p "जारी रखने के लिए Enter..." ;;


        0) exit ;;
        *) echo "गलत चयन!" ;;
    esac
}
log_action "Ping scan on $target – result: $?"

clear
show_banner
while true; do main_menu; done
