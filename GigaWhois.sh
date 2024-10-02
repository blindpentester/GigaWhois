#!/bin/bash

# GigaWhois: Perform a deep WHOIS lookup and collect detailed information.
# Supports domain names, IP addresses, CIDR blocks, ASNs, and organization lookups.
# Detects related CIDR blocks, ASNs, and subdomains owned by the organization.

GigaWhois() {
    # Ensure the required utilities are installed
    for cmd in whois dig jq curl grep awk tee; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "[  ୧༼ಠ益ಠ༽୨  ] Error: $cmd is not installed. Please install it to use GigaWhois."
            return 1
        fi
    done

    # Function Arguments and Usage
    local input="$1"
    local output_format="$2"  # json or txt (default: txt)
    local output_file="$3"    # Optional output file
    local filter="$4"         # Optional filter keyword

    # Check if input is empty
    if [[ -z "$input" ]]; then
        echo "[  ୧༼ಠ益ಠ༽୨  ] Usage: GigaWhois <domain|ip|cidr|asn|org_name> [output_format: txt/json] [output_file] [filter]"
        return 1
    fi

    # Set default output file if not specified
    if [[ -z "$output_file" ]]; then
        output_file="gigawhois_output.$output_format"
    fi

    # Determine output format
    if [[ "$output_format" != "json" && "$output_format" != "txt" ]]; then
        output_format="txt"  # Default to txt if not specified
    fi

    # Create temporary files for processing
    tmp_output=$(mktemp)
    tmp_subdomains=$(mktemp)
    arin_org_ids=$(mktemp)   # Temporary file to store ARIN organization IDs
    consolidated_output=$(mktemp) # Temporary file to consolidate results

    # Function to perform WHOIS query on different servers and save to consolidated output
    function query_whois_server() {
        local server="$1"
        local query="$2"
        local server_name="$3"

        echo "-----------------------------------------------------------------" | tee -a "$consolidated_output"
        echo "Querying $server_name for $query..." | tee -a "$consolidated_output"
        whois -h "$server" "$query" 2>&1 | tee -a "$consolidated_output"
        echo "-----------------------------------------------------------------" | tee -a "$consolidated_output"
    }

    # Determine the type of input and perform the initial WHOIS lookup
    if [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # IP Address Input
        lookup_type="IP Address"
        whois_output=$(whois "$input" | tee -a "$consolidated_output")
    elif [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
        # CIDR Block Input
        lookup_type="CIDR Block"
        whois_output=$(whois -h whois.cymru.com " -v $input" | tee -a "$consolidated_output")
    elif [[ "$input" =~ ^AS[0-9]+$ || "$input" =~ ^[0-9]+$ ]]; then
        # ASN Input
        lookup_type="ASN"
        whois_output=$(whois -h whois.cymru.com " -v AS$input" | tee -a "$consolidated_output")
    elif [[ "$input" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        # Domain Name Input
        lookup_type="Domain"
        whois_output=$(whois "$input" | tee -a "$consolidated_output")

        # Check if the domain is using Cloudflare and look for subdomains
        if echo "$whois_output" | grep -iq "cloudflare"; then
            echo "[ (⊙_☉) ] Detected Cloudflare. Searching for non-Cloudflare subdomains..."
            curl -s "https://crt.sh/?q=%25.$input&output=json" | jq -r '.[].name_value' | sort -u > "$tmp_subdomains"
            while read -r subdomain; do
                subdomain_whois=$(whois "$subdomain" | tee -a "$consolidated_output")
                echo "Subdomain: $subdomain"
                echo "$subdomain_whois" >> "$tmp_output"
            done < "$tmp_subdomains"
        fi
    else
        # Organization Name Input
        lookup_type="Organization"
        echo "[ (⊙_☉) ] Searching for all records related to organization: $input"

        # Query ARIN, RIPE, APNIC, and other regional WHOIS servers for the organization
        query_whois_server "whois.arin.net" "n $input" "whois.arin.net"
        query_whois_server "whois.ripe.net" "$input" "whois.ripe.net"
        query_whois_server "whois.apnic.net" "$input" "whois.apnic.net"
        query_whois_server "whois.lacnic.net" "$input" "whois.lacnic.net"
        query_whois_server "whois.afrinic.net" "$input" "whois.afrinic.net"

        # Use ipinfo.io API to find ASNs and CIDR blocks for the organization name
        echo "[ (⊙_☉) ] Querying ipinfo.io for additional information on organization: $input"
        ipinfo_output=$(curl -s "https://ipinfo.io/org/$input" || echo "")
        if [[ -n "$ipinfo_output" ]]; then
            echo "$ipinfo_output" >> "$consolidated_output"
        fi

        # If ipinfo.io fails, try using BGPView API to gather more details
        echo "[ (⊙_☉) ] Querying BGPView API for additional information..."
        bgpview_output=$(curl -s "https://api.bgpview.io/search?query_term=$input" || echo "")
        if [[ -n "$bgpview_output" ]]; then
            echo "$bgpview_output" >> "$consolidated_output"
        fi
    fi

    # Save the consolidated output to the specified output file
    if [[ "$output_format" == "json" ]]; then
        # Convert the consolidated output to a structured JSON format using jq
        cat "$consolidated_output" | jq -R -s '.' > "$output_file"
    else
        # Save as plain text format
        cat "$consolidated_output" | tee "$output_file"
    fi

    # Apply filtering if a filter parameter is specified
    if [[ -n "$filter" ]]; then
        echo "[ (⊙_☉) ] Applying filter: $filter"
        grep -i "$filter" "$output_file" | tee "${output_file%.*}_filtered.${output_file##*.}"
        echo "[ ಠ‿ಠ ] Filtered results saved to: ${output_file%.*}_filtered.${output_file##*.}"
    fi

    # Clean up temporary files
    rm -f "$tmp_output" "$tmp_subdomains" "$arin_org_ids" "$consolidated_output"

    echo "[ ಠ‿ಠ ] GigaWhois completed. Output saved to: $output_file"
}

# Example Usage:
# GigaWhois example.com json output.json "CIDR"
# GigaWhois 8.8.8.8 txt output.txt "email"
# GigaWhois AS15169 txt "" "netname"
# GigaWhois "Google LLC" json google_info.json "ORG"
