# Gandi Dynamic DNS

 If you have a dynamically assigned IP address from your ISP you can run this script on a cron timer to automatically update a Gandi DNS A record to your current public IP address.

 This is useful if you run a service such as a webserver or VPN on your home network and want to remotely access it using a domain name. 
 
 The script uses Gandi's LiveDNS API v5. It also uses https://ifconfig.co to determine the current public IP address, but you can change this in the script to something else if you prefer.

Note: currently only supports A records and IPv4 addresses

## Requirements

The following packages must be installed:

- curl
- jq

`curl` is used to interact with the Gandi API.

`jq` is used to read the JSON response from the API.

Install these with:

```
# Ubuntu/Debian
sudo apt install curl jq
```

## Setup

You will need to get a Gandi API key. 

- Visit [https://account.gandi.net/](https://account.gandi.net/)
- Go to `Security` and look at the `Production API Key`
- Securely record the API Key, you only get to see it once otherwise you will have to regenerate another key.

Now enter the API Key into `api_key.secret.sample` file here, then rename the file to `api_key.secret`

### File Permissions

Set the permission on the `api_key.secret` file so only you can read/write it:

```
chmod 600 api_key.secret
```

Set the permission on the `gandi-dynamic-dns.sh` script so only you can read/write/execute it:

```
chmod 700 gandi-dynamic-dns.sh
```

If you are running the script as root (such as through cron or systemd timer) change ownership of the files to root:

```
sudo chown root:root api_key.secret gandi-dynamic-dns.sh
```

## Usage

You can manually run the script with the fully qualified domain name to update, e.g.

```
./gandi-dynamic-dns.sh www.example.com
```

### cron

To automatically run the script using `cron`, open the crontab for root:

```
sudo crontab -e
```

Enter this line in the file substituting in the following values:

- the path to the script's directory
- the fully qualified domain name you want to update.

```
# Update Gandi DNS with current public IP address
0 * * * * sh /home/bob/gandi-dynamic-dns/gandi-dynamic-dns.sh www.example.com
```

In the example above the script will run hourly, change this to your needs.