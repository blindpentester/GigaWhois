# GigaWhois: Deep WHOIS Lookup Tool 🔍

GigaWhois is a powerful bash-based WHOIS lookup tool designed to collect detailed information on domain names, company/organization names, IP addresses, CIDR blocks, and Autonomous System Numbers (ASNs). It leverages multiple WHOIS servers and external APIs to provide comprehensive data, including ASNs, CIDR blocks, ownership information, and more.

## Features ✨

- **Supports Multiple Input Types**: Perform lookups on domains, organization names, IP addresses, CIDR blocks, and ASNs.
- **Multi-WHOIS Queries**: Queries multiple WHOIS servers (e.g., ARIN, RIPE, APNIC) for enhanced data collection.
- **Cloudflare Subdomain Detection**: Detects and finds non-Cloudflare subdomains using `crt.sh`.
- **Detailed ASN and CIDR Block Lookup**: Uses `ipinfo.io` and `BGPView API` for additional information.
- **Filtering Capabilities**: Extract specific information such as CIDR blocks, email addresses, or ASN details.
- **Output Options**: Supports output in both `txt` and `json` formats.

## Prerequisites 📋

Ensure the following tools are installed on your system:

- `whois`
- `dig`
- `jq`
- `curl`
- `grep`
- `awk`
- `tee`

### Installation 🛠️

Install the required tools using `apt-get` (for Debian-based systems) or `brew` (for macOS):

```bash
# For Debian-based systems
sudo apt-get install whois dnsutils jq curl grep awk -y

# For macOS using Homebrew
brew install whois jq curl grep awk
```

## Usage 🚀

Clone the repository and add the script to your environment path or run it directly:

```bash
git clone <your-repository-url>
cd <your-repository-directory>
chmod +x gigawhois.sh
./gigawhois.sh <parameters>
```

### Example Commands 🔧

#### 1. **Domain Name Lookup**

```bash
GigaWhois example.com txt domain_info.txt
```
Performs a WHOIS lookup for the domain `example.com` and saves the output to `domain_info.txt`.

#### 2. **Company/Organization Name Lookup**

```bash
GigaWhois "Facebook" json facebook_info.json
```
Searches for all ASNs, IP blocks, and other details related to the organization `Facebook` and saves the result to `facebook_info.json`.

#### 3. **IP Address Lookup**

```bash
GigaWhois 8.8.8.8 txt google_ip_info.txt
```
Queries details about the IP address `8.8.8.8` and saves the information to `google_ip_info.txt`.

#### 4. **CIDR Block Lookup**

```bash
GigaWhois 192.168.0.0/24 json cidr_info.json
```
Performs a detailed lookup for the CIDR block `192.168.0.0/24` and saves the result in JSON format as `cidr_info.json`.

#### 5. **ASN Lookup**

```bash
GigaWhois AS15169 txt google_asn_info.txt
```
Finds information related to ASN `AS15169` (which belongs to Google) and saves it to `google_asn_info.txt`.

## Filtering Results 🎯

You can filter the output for specific fields using the optional `filter` parameter:

### Example Filters:

#### 1. **Filter for CIDR Blocks**

```bash
GigaWhois "Facebook" txt facebook_cidr_info.txt "CIDR"
```
Finds all information related to `Facebook` and then filters the results to only include lines that contain CIDR blocks.

#### 2. **Filter for Email Addresses**

```bash
GigaWhois "Google LLC" txt google_emails.txt "email"
```
Looks up `Google LLC` and then filters the results to only include lines with email addresses.

#### 3. **Filter for ASN Information**

```bash
GigaWhois 8.8.8.8 txt google_asn_filtered.txt "AS"
```
Performs a lookup for `8.8.8.8` and filters the output to include only lines with ASN-related information.

## Additional Parsing and Filtering 📑

After running `GigaWhois`, you can further parse specific fields using additional commands:

### Extracting CIDR Blocks from a Text File

```bash
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+' facebook_info.txt
```

### Extracting Email Addresses from JSON Output

If your output is in JSON format, use `jq` to filter specific fields:

```bash
jq -r '.[] | select(.email_contacts != null) | .email_contacts[]' facebook_info.json
```

### Extracting ASNs

Use `grep` to find ASNs:

```bash
grep -Eo 'AS[0-9]+' facebook_info.txt
```

## Contributing 🤝

Feel free to submit issues or pull requests to help improve this tool. Contributions are always welcome!

## License 📜

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

