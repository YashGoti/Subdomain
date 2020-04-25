#!/bin/bash

if [ -z $1 ];then
  echo "[Usage]:"
  echo "./subdomain.sh domain"
else
  curl -s "https://otx.alienvault.com/api/v1/indicators/domain/$1/passive_dns" | jq -r ".passive_dns[].hostname" | sort -u > /root/tmp.txt &
  curl -s "https://jldc.me/anubis/subdomains/$1" | jq -r '.' | cut -d '"' -f2 | cut -d '[' -f1 | cut -d ']' -f1 | grep . | sort -u >> /root/tmp.txt &
  curl -s "http://web.archive.org/cdx/search/cdx?url=*.$1/*&output=text&fl=original&collapse=urlkey" | sort | sed -e 's_https*://__' -e "s/\/.*//" -e 's/:.*//' -e 's/^www\.//' | sort -u >> /root/tmp.txt &
  curl -s "https://certspotter.com/api/v0/certs?domain=$1" | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | grep -w $1\$ | sort -u >> /root/tmp.txt &
  curl -s "https://crt.sh/?q=%.$1&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u >> /root/tmp.txt &
  curl -s "https://dns.bufferover.run/dns?q=.$1" | jq -r .FDNS_A[] 2>/dev/null | cut -d ',' -f2 | grep -o "\w.*$1" | sort -u >> /root/tmp.txt &
  curl -s "https://dns.bufferover.run/dns?q=.$1" | jq -r .RDNS[] 2>/dev/null | cut -d ',' -f2 | grep -o "\w.*$1" | sort -u >> /root/tmp.txt &
  curl -s "https://tls.bufferover.run/dns?q=.$1" | jq -r .Results 2>/dev/null | cut -d ',' -f3 | grep -o "\w.*$1"| sort -u >> /root/tmp.txt &
  curl -s "https://api.hackertarget.com/hostsearch/?q=$1" | cut -d ',' -f1 | sort -u >> /root/tmp.txt &
  curl -s "https://rapiddns.io/subdomain/$1" | grep -oaEi "https?://[^\"\\'> ]+" | grep $1 | sed 's/https\?:\/\///' | sort -u >> /root/tmp.txt &
  curl -s "https://riddler.io/search/exportcsv?q=pld:$1" | grep -o "\w.*$1" | cut -d ',' -f6 | sort -u >> /root/tmp.txt &
  curl -s "https://www.threatcrowd.org/searchApi/v2/domain/report/?domain=$1" | jq '.subdomains' | cut -d '"' -f2 | cut -d '[' -f1 | cut -d ']' -f1 | grep . | sort -u >> /root/tmp.txt &
  curl -s "https://api.threatminer.org/v2/domain.php?q=$1&rt=5" | jq -r '.results[]' | sort -u >> /root/tmp.txt &
  curl -s "https://urlscan.io/api/v1/search/?q=domain:$1" | jq -r '.results[].page.domain' | sort -u >> /root/tmp.txt &
  curl -s "https://www.virustotal.com/ui/domains/$1/subdomains?limit=40" | grep '"id":' | cut -d '"' -f4 | sort -u >> /root/tmp.txt &
  csrftoken=$(curl -ILs https://dnsdumpster.com | grep csrftoken | cut -d " " -f2 | cut -d "=" -f2 | tr -d ";")
  curl -s --header "Host:dnsdumpster.com" --referer https://dnsdumpster.com --user-agent "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:45.0) Gecko/20100101 Firefox/45.0" --data "csrfmiddlewaretoken=$csrftoken&targetip=$1" --cookie "csrftoken=$csrftoken; _ga=GA1.2.1737013576.1458811829; _gat=1" https://dnsdumpster.com >> dnsdumpster.html &
  cat dnsdumpster.html | grep "https://api.hackertarget.com/httpheaders" | grep -o "\w.*$1" | cut -d "/" -f7 | grep '.' | sort -u
  cat /root/tmp.txt | sort -u | grep $1 | tee
  rm -rf /root/dnsdumpster.html
  rm -rf /root/tmp.txt
 fi
