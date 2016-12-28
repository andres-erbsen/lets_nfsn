#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

readonly Dir="$(dirname "$0")"
readonly RealDir="$(realpath "${Dir}")"

readonly well_known='.well-known/acme-challenge/'
declare single_cert='true'
readonly dconfig='dehydrated/config'
readonly user_site="${MAIL##*/}"
readonly user="${user_site%_*}"
readonly site="${NFSN_SITE_NAME}"
readonly instructions="instructions.txt"

if [[ "${RealDir##/home/private/}" = "${RealDir}" ]]; then
   echo "Error: This script must be placed in '/home/private'."
   exit 1
fi

function check_permission() {
   if ! perl -e 'exit(((stat($ARGV[0]))[2] & 0077) != 0);' "$1"; then
      printf "Error: overly open permissions on '%q'" "$1"
      exit 1
   fi
}

check_permission /home/private

if [[ -e "${dconfig}" ]]; then
   echo "Error: Main dehydrated config file '${dconfig}' already exists,"
   echo "and this script would overwrite it. Aborting."
   exit 1
fi

echo " + Generating configuration..."
for site_root in $(nfsn list-aliases); do
   if [[ -d "${DOCUMENT_ROOT}${site_root}/" ]]; then
      WELLKNOWN="${DOCUMENT_ROOT}${site_root}/${well_known}"
      CONFIGDIR="dehydrated/certs/${site_root}/"
      mkdir -p "${WELLKNOWN}" "${CONFIGDIR}"
      echo "WELLKNOWN='${WELLKNOWN}'" > "${CONFIGDIR}/config"
      unset single_cert
   fi
done

printf '' > "$dconfig"
if [[ "${single_cert:+true}" ]]; then
   echo " + Generating single-site configuration..."
   mkdir -p "${DOCUMENT_ROOT}${well_known}"
   echo "WELLKNOWN='${DOCUMENT_ROOT}${well_known}'" >> "$dconfig"
fi

echo " + Extra global configuration..."
echo "HOOK=\$BASEDIR/../nfsn-hook.sh

#CONTACT_EMAIL=invalid@example.com   # uncomment and fill in

CA='https://acme-v01.api.letsencrypt.org/directory'   # real letsencrypt server
#CA='https://acme-staging.api.letsencrypt.org/directory'   # staging server (no rate limits)" >> "$dconfig"

echo " + Generating domains.txt..."
nfsn ${single_cert:+-s} list-aliases > dehydrated/domains.txt

weekdays=(Mon Tues Wednes Thurs Fri Satur Sun)
printf "There are still a few things left to do.

0. Edit '%s' and fill in your email address, or
   else you won't get expiry warnings in case this script stops working.

1. Run ./nfsn-cron.sh manually and check that it works correctly.

2. Add nfsn-cron.sh to your scheduled tasks (i.e. 'cron') so that the
   certificates will be renewed automatically. To do that, navigate to

   https://members.nearlyfreespeech.net/%s/sites/%s/cron

   and use the following settings:

	Tag:                  dehydrated
	URL or Shell Command: %q
	User:                 me
	Where:                Run in ssh environment   (important!)
	Hour:                 %d
	Day of Week:          %s
	Date:                 *

3. You're done!

Note that these exact instructions have also been written to file '%s'.
" \
       "$dconfig" "${user}" "${site}" \
       "$(realpath nfsn-cron.sh)" "$(( $RANDOM % 24 ))" \
       "${weekdays[$(( $RANDOM % 7 ))]}day" "${instructions}" \
       > "${instructions}"
echo
echo
cat "${instructions}"
