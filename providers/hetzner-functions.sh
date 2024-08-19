#!/bin/bash
AXIOM_PATH="$HOME/.axiom"
source "$AXIOM_PATH/interact/includes/appliance.sh"
LOG="$AXIOM_PATH/log.txt"

# takes no arguments, outputs JSON object with instances
instances() {
	hcloud server list -o json
}

instance_id() {
	name="$1"
	instances | jq ".[] | select(.name ==\"$name\") | .id"
}

instance_ip() {
	name="$1"
	instances | jq ".[] | select(.name ==\"$name\") | .public_net.ipv4.ip"
}

poweron() {
    instance_name="$1"
    hcloud server poweron $(instance_id $instance_name)
}

poweroff() {
	instance_name="$1"
    hcloud server shutdown $(instance_id $instance_name)
}

reboot(){
    instance_name="$1"
    hcloud server reboot $(instance_id $instance_name)
}

instance_list() {
	instances | jq -r '.[].name'
}

instance_menu() {
	instances | jq -r '.[].name' | fzf
}

quick_ip() {
	data="$1"
	ip=$(echo $data | jq -r ".[] | select(.name == \"$name\") | .public_net.ipv4.ip")
	echo $ip
}

selected_instance() {
	cat "$AXIOM_PATH/selected.conf"
}

get_image_id() {
	query="$1"
	images=$(hcloud image list -o json)
	id=$(echo $images |  jq -r ".[] | select((.name==\"$query\") and (.architecture==\"x86\")) | .id")
	echo $id
}

delete_instance() {
    name="$1"
  	id="$(instance_id "$name")"
    hcloud server delete "$id"
}

# TBD
instance_exists() {
	instance="$1"
}

list_regions() {
    hcloud location list
}

regions() {
    hcloud location list -o json | jq -r '.[].name'
}

instance_sizes() {
	echo "Needs conversion"
    #doctl compute size list -o json
}

# List DNS records for domain
list_dns() {
	domain="$1"

	echo "Needs conversion"
	# doctl compute domain records list "$domain"
}

list_domains_json() {
    echo "Needs conversion"
    # doctl compute domain list -o json
}

# List domains
list_domains() {
	echo "Needs conversion"
	# doctl compute domain list
}

list_subdomains() {
    domain="$1"

	echo "Needs conversion"
    # doctl compute domain records list $domain -o json | jq '.[]'
}

# get JSON data for snapshots
snapshots() {
	hcloud image list -o json
}

get_snapshots()
{
	hcloud image list 
}

delete_record() {
    domain="$1"
    id="$2"

	echo "Needs conversion"
    #doctl compute domain records delete $domain $id
}

delete_record_force() {
    domain="$1"
    id="$2"

	echo "Needs conversion"
    #doctl compute domain records delete $domain $id -f
}

# Delete a snapshot by its name
delete_snapshot() {
	name="$1"
	hcloud server delete "$name"
}

add_dns_record() {
    subdomain="$1"
    domain="$2"
    ip="$3"

	echo "Needs conversion"
    # doctl compute domain records create $domain --record-type A --record-name $subdomain --record-data $ip
}
 