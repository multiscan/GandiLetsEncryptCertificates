#!/bin/sh

ARCHIVE=/keybase/private/multiscan/certbot
DOMAINS="dev.jkldsa.com dev.cangiani.me"
MYEMAIL="giovanni.cangiani@gmail.com"

# NOTE: that this will only work from controlled IPs due to Gandi security
# docker run -it --entrypoint /bin/sh multiscan/certbot
# https://github.com/obynio/certbot-plugin-gandi
# https://pypi.org/project/certbot-plugin-gandi/
# https://letsencrypt.org/getting-started/
# https://certbot.eff.org/docs/using.html
# http://devblog.ocazio.com/administration/linux/how-to-generate-self-signed-wildcard-ssl-certificate/
# https://jimfrenette.com/2018/03/ssl-certificate-authority-for-docker-and-traefik/

# TODO:
# [X] all shares with containers must be temporary
# [ ] renewal: needs to recover key/cert from keybase
# [ ] cli


echo "This script was heavily resritten but never tested."
echo "  1. Edit to remove this message"
echo "  2. Test"
echo "  3. remove the --dry-run and hope it works"
exit

if ! docker image ls | grep -q multiscan/certbot  ; then
  docker build -t multiscan/certbot certbot-gandi
fi

if [ ! -d $ARCHIVE ] ; then
  echo "Could not find backup directory $ARCHIVE" >&2
  if echo $ARCHIVE | grep -q keybase ; then
    echo "Probably you need to mount keybase" >&2
  fi
  exit 1
fi

# All this copying back and forrth is due to the fact that docker cannot mount keybase fs
tmp=$(mktemp -d /tmp/certbot_XXXXXX)
rsync -av $ARCHIVE/ $tmp/
for dom in $DOMAINS ; do 
  docker run -it --rm \
           -v "$tmp/etc:/etc/letsencrypt" \
           -v "$tmp/log:/var/log/letsencrypt" \
           -v "$tmp/gandi.ini:/tmp/gandi.ini" \
           multiscan/certbot certonly \
           --text \
           --non-interactive \
           --agree-tos --email $MYEMAIL \
           -a certbot-plugin-gandi:dns --certbot-plugin-gandi:dns-credentials /tmp/gandi.ini \
           --dry-run \
           -d \*.$dom
           # --rsa-key-size 4096 \
           # --force-renewal --reinstall \
           # --standalone \
done
rsync -av $tmp/ $ARCHIVE/
rm -rf $tmp
