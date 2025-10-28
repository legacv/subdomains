#!/bin/bash

# usage: collect ASN, subdomains, open ports, & other information of note for a given domain
# legacv 2025
# MIT license

# workflow:
# domain > sublister > sublister > dnsdumpster > 3 lists
# ASN > IPs (shodan) > 1 list > resolve > +1 list
# 4 domain lists > concatenate > sort, uniq > spit
# spit > check active w/ httpx
# IP list >


source ".env"

# user input and other bullshit
init () {
        read -p "what's your domain? " domain
        read -p "what's your asn? " asn
        # forgot vars are global by default lol
        read -p "any special User-Agent? " userAgent
        if [ -z "$userAgent" ]; then
                userAgent='Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:136.0) Gecko/20100101 Firefox/136.'
        fi
        header='X-HackerOne-Research: legacv'
        mkdir -p $domain
        return 0
}

# resolves a domain
resolve () {
        IP=$(dig "$1" +short)
}

# queries subfinder for subdomains
getSubdomains () {
        subfinder -duc -silent -sources "alienvault,anubis,commoncrawl,crtsh,digitorus,dnsdumpster,hackertarget,rapiddns,riddler,sitedossier,waybackarchive,shodan,virustotal" -d $1 >> $2
}

# queries shodan using an api key, && parses output with jq, && resolves each one with resolve,
# fromASN () {}

# checks if subdomain is alive with httpx, sorts into other list if not
lifeCheck () {
        httpx-toolkit -silent -fc 404,403 -l "$1" -H "$2" #-rl 2
}

# grabs endpoints from URL
# TODO: can be spotty - grab first field, delimited by spaces
findLinks () {
        python3 /usr/bin/LinkFinder/linkfinder.py -i $1 -d -o cli > $2
}

main () {

        init
        echo "[*] doing subdomains..."
        getSubdomains $domain "${domain}/subfinder"
        # sort them so less work for lifecheck
        cat "${domain}/subfinder" | sort | uniq > "${domain}/temp"
        echo "[*] performing health checks..."
        lifeCheck "${domain}/temp" "${header}" > "${domain}/urls"
        return 0
}

main
