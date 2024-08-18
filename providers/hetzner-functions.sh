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