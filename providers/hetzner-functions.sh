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

instance_pretty() {
  data=$(instances)
  #number of servers
  servers=$(echo $data|jq -r '.[]|.id'|wc -l )
  #default size from config file
  type="$(jq -r .default_size "$AXIOM_PATH/axiom.json")"
  #monthly price of server type 
price=$(hcloud server-type list -o json | jq -r ".[] | select(.name == \"$type\") | .prices[0].price_monthly.net")
  totalPrice=$(echo "$price * $servers" | bc)
  header="Instance,Primary Ip,Region,Memory,Status,\$/M"
  totals="_,_,_,Instances,$servers,Total,\$$totalPrice"
fields=".[] | [.name, .public_net.ipv4.ip, .datacenter.location.name, .server_type.memory, .status, \"$price\"] | @csv"

# Printing part
# sort -k1 sorts all data by label/instance/server name
(echo "$header" && echo "$data" | jq -r "$fields" | sort -k1 && echo "$totals") | sed 's/"//g' | column -t -s, | perl -pe '$_ = "\033[0;37m$_\033[0;34m" if($. % 2)'
}

selected_instance() {
	cat "$AXIOM_PATH/selected.conf"
}

get_image_id() {
	query="$1"
	images=$(hcloud image list -o json)
	if [[ $query == *"axiom-"* ]]; then
   		id=$(echo $images |  jq -r ".[] | select((.description==\"$query\") and (.architecture==\"x86\")) | .id")
	else
    	id=$(echo $images |  jq -r ".[] | select((.name==\"$query\") and (.architecture==\"x86\")) | .id")
	fi
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
	hcloud image list -t snapshot -o json
}

get_snapshots()
{
	hcloud image list -t snapshot
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
 
 msg_success() {
	echo -e "${BGreen}$1${Color_Off}"
	echo "SUCCESS $(date):$1" >> $LOG
}

msg_error() {
	echo -e "${BRed}$1${Color_Off}"
	echo "ERROR $(date):$1" >> $LOG
}

msg_neutral() {
	echo -e "${Blue}$1${Color_Off}"
	echo "INFO $(date): $1" >> $LOG
}

# takes any number of arguments, each argument should be an instance or a glob, say 'omnom*', returns a sorted list of instances based on query
# $ query_instances 'john*' marin39
# Resp >>  john01 john02 john03 john04 nmarin39
query_instances() {
	droplets="$(instances)"
	selected=""

	for var in "$@"; do
		if [[ "$var" =~ "*" ]]
		then
			var=$(echo "$var" | sed 's/*/.*/g')
			selected="$selected $(echo $droplets | jq -r '.[].name' | grep "$var")"
		else
			if [[ $query ]];
			then
				query="$query\|$var"
			else
				query="$var"
			fi
		fi
	done

	if [[ "$query" ]]
	then
		selected="$selected $(echo $droplets | jq -r '.[].name' | grep -w "$query")"
	else
		if [[ ! "$selected" ]]
		then
			echo -e "${Red}No instance supplied, use * if you want to delete all instances...${Color_Off}"
			exit
		fi
	fi

	selected=$(echo "$selected" | tr ' ' '\n' | sort -u)
	echo -n $selected
}

query_instances_cache() {
	selected=""
    ssh_conf="$AXIOM_PATH/.sshconfig"

	for var in "$@"; do
        if [[ "$var" =~ "-F=" ]]; then
            ssh_conf="$(echo "$var" | cut -d "=" -f 2)"
        elif [[ "$var" =~ "*" ]]; then
			var=$(echo "$var" | sed 's/*/.*/g')
            selected="$selected $(cat "$ssh_conf" | grep "Host " | awk '{ print $2 }' | grep "$var")"
		else
			if [[ $query ]];
			then
				query="$query\|$var"
			else
				query="$var"
			fi
		fi
	done

	if [[ "$query" ]]
	then
        selected="$selected $(cat "$ssh_conf" | grep "Host " | awk '{ print $2 }' | grep -w "$query")"
	else
		if [[ ! "$selected" ]]
		then
			echo -e "${Red}No instance supplied, use * if you want to delete all instances...${Color_Off}"
			exit
		fi
	fi

	selected=$(echo "$selected" | tr ' ' '\n' | sort -u)
	echo -n $selected
}

#  generate the SSH config depending on the key:value of generate_sshconfig in accout.json
#
generate_sshconfig() {
accounts=$(ls -l "$AXIOM_PATH/accounts/" | grep "json" | grep -v 'total ' | awk '{ print $9 }' | sed 's/\.json//g')
current=$(ls -lh "$AXIOM_PATH/axiom.json" | awk '{ print $11 }' | tr '/' '\n' | grep json | sed 's/\.json//g') > /dev/null 2>&1
droplets="$(instances)"
sshnew="$AXIOM_PATH/.sshconfig.new$RANDOM"
echo -n "" > $sshnew
echo -e "\tServerAliveInterval 60\n" >> $sshnew
sshkey="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.sshkey')"
echo -e "IdentityFile $HOME/.ssh/$sshkey" >> $sshnew
generate_sshconfig="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.generate_sshconfig')"

if [[ "$generate_sshconfig" == "private" ]]; then

 echo -e "Warning your SSH config generation toggle is set to 'Private' for account : $(echo $current)."
 echo -e "axiom will always attempt to SSH into the instances from their private backend network interface. To revert run: axiom-ssh --just-generate"
 for name in $(echo "$droplets" | jq -r '.[].name')
 do
 ip=$(echo "$droplets" | jq -r ".[] | select(.name==\"$name\") | .private_net.ipv4.ip")
 if [[ -n "$ip" ]]; then
  echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $sshnew
 fi
 done
 mv $sshnew $AXIOM_PATH/.sshconfig

 elif [[ "$generate_sshconfig" == "cache" ]]; then
 echo -e "Warning your SSH config generation toggle is set to 'Cache' for account : $(echo $current)."
 echo -e "axiom will never attempt to regenerate the SSH config. To revert run: axiom-ssh --just-generate"

 # If anything but "private" or "cache" is parsed from the generate_sshconfig in account.json, generate public IPs only
 #
 else
 for name in $(echo "$droplets" | jq -r '.[].name')
 do
 ip=$(echo "$droplets" | jq -r ".[] | select(.name==\"$name\") | .public_net.ipv4.ip")
 if [[ -n "$ip" ]]; then
  echo -e "Host $name\n\tHostName $ip\n\tUser op\n\tPort 2266\n" >> $sshnew
 fi
 done
 mv $sshnew $AXIOM_PATH/.sshconfig
fi


 if [ "$key" != "null" ]
 then
 gen_app_sshconfig
 fi
}

image_id() {
	name="$1"
	snapshots | jq -r ".[] | select(.name==\"$name\") | .id"
}

create_instance() {
	name="$1"
	image_id="$2"
	size_slug="$3"
	region="$4"
	boot_script="$5"

  sshkey="$(cat "$AXIOM_PATH/axiom.json" | jq -r '.sshkey')"
  sshkey_fingerprint="$(ssh-keygen -l -E md5 -f ~/.ssh/$sshkey.pub | awk '{print $2}' | cut -d : -f 2-)"
  keyid=$(hcloud ssh-key create --name $sshkey \
    --public-key-from-file ~/.ssh/$sshkey.pub 2>/dev/null) ||
  keyid=$(hcloud ssh-key list | grep "$sshkey_fingerprint" | awk '{ print $1 }')

	hcloud server create  --type "$size_slug" --location "$region" --image "$image_id" --name "$name" --ssh-key "$keyid" --user-data-from-file "$boot_script" 2>&1 >> /dev/null
}

# Function used for splitting $src across $instances and rename the split files.
lsplit() {
	src="$1"
	instances=$2
	total=$(echo $instances|  tr ' ' '\n' | wc  -l | awk '{ print $1 }')
	orig_pwd=$(pwd)

	lines=$(wc -l $src | awk '{ print $1 }')
	lines_per_file=$(bc <<< "scale=2; $lines / $total" | awk '{print int($1+0.5)}')
	id=$(echo "$instances" | md5sum | awk '{ print $1 }' |  head -c5)
	split_dir="$AXIOM_PATH/tmp/$id"

	rm  -rf $split_dir  >> /dev/null  2>&1
	mkdir -p $split_dir
	cp $src $split_dir

	cd $split_dir
	split -l $lines_per_file $src
	rm $src
	a=1

	for f in $(ls | grep x); do
		mv $f $a.txt
		a=$((a+1))
	done

	i=1
	for instance in $(echo $instances | tr ' ' '\n'); do
		mv $i.txt $instance.txt
		i=$((i+1))
	done

	cd $orig_pwd
	echo -n $split_dir
}

# Check if host is in .sshconfig, and if it's not, regenerate sshconfig
conf_check() {
	instance="$1"

	l="$(cat "$AXIOM_PATH/.sshconfig" | grep "$instance" | wc -l | awk '{ print $1 }')"

	if [[ $l -lt 1 ]]; then
		generate_sshconfig	
	fi
}
