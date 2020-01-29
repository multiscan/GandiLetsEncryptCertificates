#!/bin/sh

set -e

MYEMAIL="giovanni.cangiani@gmail.com"
ARCHIVE="certbot"

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

usage() {
  cat <<-__EOF
    This script will renew all the let's encrypt * certificates 
    in your archive directory. 
    The domains are supposed to be registered on gandi.net. 
    The script expects to find in the archive directory a 'gandi.ini' file 
    containing the following line:
      certbot_plugin_gandi:dns_api_key=YOUR_GANDI_DNS_API_KEY
    For more infos about the api key, see 
    https://docs.gandi.net/en/domain_names/advanced_users/api.html

    usage:
      $0 [-y] [-e EMAIL] [-a DIR]
    options:
      -y       : Disable dry-run and actually do the job.
      -e EMAIL : Set e-mail address to be used by certbot (default: $MYEMAIL)
      -a DIR   : Set the name of the archive directory (default: $ARCHIVE)
                 If this is an absolute path or one relative to 
                 the current directory, then it is take as is 
                 otherwise it is appended to your private keybase directory.
__EOF
}

DRY="--dry-run"
DOMAINS=""
while [ $# -gt 0 ] ; do
case $1 in
-y) DRY=""
    shift 1
    ;;
-e) MYEMAIL=$2
    shift 2
    ;;
-a) ARCHIVE=$2
    shift 2
    ;;
*) DOMAINS="$DOMAINS $1"
   shift 1
   ;;
esac
done 

if [[ "$1" =~ ^/|^./ ]] ; then
  # archive dir is a standard directory not in keybase
  echo "Archive directory is a standard one: $ARCHIVE"
else
  # archive dir is in keybase
  which -s keybase || {
    echo "keybase not found"
    exit 1
  }
  keybase status >/dev/null 2>/dev/null || {
    echo "Keybase is not running. Please start it."
    exit 2
  }

  kbuser=$(keybase status | awk '/^Username:/{print $2}')

  if [ -z "$kbuser" ] ; then
    echo "Something wrong while guessing Keybase user" >&2
    exit 1
  fi

  kbdir="/keybase/private/$kbuser"

  if [ ! -d $kbdir ] ; then
    echo "Could not find Keybase private directory ($kbdir) for user $kbuser" >&2
    echo "May be keybase is not running or there is an error somewhere"
    exit 1
  fi

  ARCHIVE="$kbdir/$ARCHIVE"
  echo "Archive directory is in keybase: $ARCHIVE"
fi

[ -d $ARCHIVE ] || {
  echo "Archive directory $ARCHIVE not found."
  usage
  exit 1
}

[ -f $ARCHIVE/gandi.ini ] || {
  echo "Gandi config file $ARCHIVE/gandi.ini not found!"
  usage
  exit 1
}

if [ "$DRY" == "--dry-run" ] ; then
  echo "Running in dry-run mode to test certbot. Restart with -y to actually do the job."
else
  echo "This is the real run. We will create the following certificates:"
  for dom in $DOMAINS ; do 
    echo "  *.$dom"
  done

  read -p "Are you sure that you want proceed ? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]] ; then
    echo "Ok let's proceed"
  else
    echo "Ok. See you next time then."
    exit
  fi
fi

if ! docker image ls | grep -q multiscan/certbot  ; then
  echo "Building docker image"
  docker build -t multiscan/certbot certbot-gandi
fi

# All this copying back and forth is due to the fact that 
# docker cannot mount keybase fs but also as a backup
tmp=$(mktemp -d /tmp/certbot_XXXXXX)
rsync -av $ARCHIVE/ $tmp/
trap "echo rm -rf $tmp" EXIT

for dom in $DOMAINS ; do 
  docker run -it --rm \
           -v "$tmp/etc:/etc/letsencrypt" \
           -v "$tmp/log:/var/log/letsencrypt" \
           -v "$tmp/gandi.ini:/tmp/gandi.ini" \
           multiscan/certbot renew \
           $DRY \
           --text \
           --non-interactive \
           --agree-tos --email $MYEMAIL \
           -a certbot-plugin-gandi:dns --certbot-plugin-gandi:dns-credentials /tmp/gandi.ini \
           -d \*.$dom
  if [ -z "$DRY" ] ; then
    rsync -av $tmp/ $ARCHIVE/
  fi
done
