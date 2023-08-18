#!/usr/bin/bash

verbose=false
output_directory=./out/
urls=""

# Help function to display usage information
display_help() {
    echo "Usage: $(basename "$0") [-h] [-v] [-o] -u <url list>"
    echo "  -u    URL/domain list to use"
    echo "  -o    Set the output directory (default: ./out/)"
    echo "  -v    Enable verbose output"
    echo "  -h    Display this help message"
}

options=$(getopt -o hvo:u: --long help,verbose,output:,urls: -n "$0" -- "$@")
eval set -- "$options"

while true; do
    case "$1" in
        -h | --help) display_help; exit 0 ;;
        -v | --verbose) verbose=true; shift ;;
        -o | --output) output_directory="$2"; shift 2 ;;
        -u | --urls) urls="$2"; shift 2 ;;
        --) shift; break ;;
        *) echo "Invalid option: $1"; display_help; exit 1 ;;
    esac
done

if [ "$urls" = "" ]; then
    echo "Error: Provide a URL/domain list with -u"
    echo
    display_help
    exit 1

elif [ ! -f "$urls" ]; then
    echo "Error: The list you provided does not exist."
    echo
    display_help
    exit 1
fi




mkdir -p $output_directory/status

probe() {
    echo
    echo "[+] probing domains"
    echo
    local urls=$1
    if [ $verbose = true ]
    then
            tmp_file=$(mktemp)
            cat $urls | httprobe -prefer-https -t 3000  | tee $tmp_file
            probed=$(cat $tmp_file)
            rm "$tmp_file"
    else
        probed=$(cat $urls | httprobe -prefer-https -t 3000  | tee $tmp_file)
        
    fi
}

getCodes() {
    echo
    echo "[+] getting Status codes"
    echo

    urls=$1
    if [ $verbose = true ]
    then
        tmp_file=$(mktemp)
        cat $urls | httpx -s -sd -timeout 3 -sc 2>/dev/null | tee $tmp_file
        status_codes=$(cat $tmp_file)
        rm "$tmp_file"
    else
        status_codes=$(cat $urls | httpx -s -sd -timeout 3 -sc 2>/dev/null)
    fi
}



probe $urls $verbose
echo "$probed" > $output_directory/probed
echo "$probed" | sed -E 's/https?:\/\///' > $output_directory/probed_clean
getCodes $urls true 
echo "$status_codes" > $output_directory/status/all
echo "$status_codes" | grep 20 | awk -F ' ' '{print $1}' > $output_directory/status/ok_domains
echo "$status_codes" | grep 40 | awk -F ' ' '{print $1}' > $output_directory/status/err_domains
echo "$status_codes" | grep 50 | awk -F ' ' '{print $1}' > $output_directory/status/interr_domains
echo "$status_codes" | grep 30 | awk -F ' ' '{print $1}' > $output_directory/status/redirect_domains

echo
echo "[+] done"
echo
exit 0
