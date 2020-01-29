# Gandi Lets Encrypt Certificates

Script for creating or renewing *.MYDOMAIN certificates using Let's Encrypt for domains hosted on Gandi. 

## Setup
 1. Create an _archive_ directory. I use to keep mine in Keybase but you can have it elsewhere in your filesystem.
 1. In the archive directory create a `gandi.ini` configuration file that will look like the following line:
    ```
    certbot_plugin_gandi:dns_api_key=YOUR_GANDI_DNS_API_KEY
    ```
    where `YOUR_GANDI_DNS_API_KEY` have to be generated from your Gandi dashboard as
    explained [here](https://docs.gandi.net/en/domain_names/advanced_users/api.html)

## Generate
To generate your brand new certificates first test that everything is okay:
```
./cbot_gandi_create.sh -e YOUR_EMAIL -a YOUR_ARCHIVE_DIR domain_name
```
then run it again adding a `-y` option.

Your certificates will be located in a folder named `etc/live/` in your archive directory.
For [traefik](https://github.com/multiscan/dev_traefik), the two files that are needed are
 * `privkey.pem`
 * `fullchain.pem` 

## Renew
Similarly, you can renew certs that are about to expire with `./cbot_gandi_renew.sh`:
```
./cbot_gandi_create.sh -e YOUR_EMAIL -a YOUR_ARCHIVE_DIR
```
Again, add the `-y` option to execute. 
