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

main_menu() {
    echo -e "${YELLOW}[1] हैलो वर्ल्ड टूल"
    echo -e "${YELLOW}[2] डायरेक्टरी स्कैन + HTML रिपोर्ट${RESET}"
    echo -e "[0] बाहर निकलें${RESET}"
    read -p "आपका विकल्प: " ch
    case $ch in
        1)
            echo -e "${GREEN}~ हेलो वर्ल्ड, टूलकिट शुरू!${RESET}"
            ;;
        2)
    generate_html_report
    read -p "जारी रखने के लिए Enter..." ;;

        0) exit ;;
        *) echo "गलत चयन!" ;;
    esac
}

clear
show_banner
while true; do main_menu; done
