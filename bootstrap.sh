#!/bin/bash -xe

hostname=`hostname`
ipv4=`hostname -I`

update_packages() {
    echo -e "[INFO] Updating the machine ${hostname}"
        yum update -y

    echo -e "[INFO] Install necessary packages...."
        yum install -y epel-release git
}

tier1() {
    echo -e "[INFO] Installing nginx on ${hostname}"
        yum install -y nginx

    echo -e "[INFO] Set nginx to start on boot"
        systemctl enable nginx

    echo -e "[INFO] Starting nginx server"
        systemctl start nginx
        if [ -e /var/run/nginx.pid ]
            then 
                echo "[INFO] nginx is running"
            else
                echo "[INFO] nginx is not running, starting nginx."
                systemctl start nginx
        fi

    echo -e "[INFO] Cloning bash_scripts configuration"
        git clone https://github.com/imm-industry05/bash_scripts.git bash_scripts
    
    echo -e "[INFO] Denying ALL Hosts...."
        cat  hosts.deny > /etc/hosts.deny

    echo -e "[INFO] Allowing ${ipv4} on ${hostname}"
        sed -e "s/sshd: ipv4/sshd: ${ipv4}/g" hosts.allow
        cat hosts.allow > /etc/hosts.allow
    
    echo -e  "[INFO] Checkin hosts.allow"
        cat /etc/hosts.allow

    echo -e "[INFO] Allowing http and https service."
        firewall-cmd --zone=public --permanent --add-service=https
        firewall-cmd --zone=public --permanent --add-service=http

    echo -e "[INFO] Allowing port 80 and 443."
        firewall-cmd --zone=public --permanent --add-port=80/tcp
        firewall-cmd --zone=public --permanent --add-port=443/tcp
    
    echo -e "[INFO] Reloading firewall-cmd"
        firewall-cmd --reload
}

tier2() {
    echo -e "[INFO] Install httpd on ${hostname}"
        yum install -y httpd

    echo -e "[INFO] Cloning bash_scripts configuration"
        git clone https://github.com/imm-industry05/bash_scripts.git bash_scripts
    
    echo -e "[INFO] Denying ALL Hosts...."
        cat  hosts.deny > /etc/hosts.deny

    echo -e "[INFO] Allowing ${ipv4} on ${hostname}"
        sed -e "s/sshd: ipv4/sshd: ${ipv4}/g" hosts.allow
        cat hosts.allow > /etc/hosts.allow
    
    echo -e  "[INFO] Checkin hosts.allow"
        cat /etc/hosts.allow

    echo -e "[INFO] Allowing http and https service."
        firewall-cmd --zone=public --permanent --add-service=https
        firewall-cmd --zone=public --permanent --add-service=http

    echo -e "[INFO] Allowing port 80 and 443."
        firewall-cmd --zone=public --permanent --add-port=80/tcp
        firewall-cmd --zone=public --permanent --add-port=443/tcp
    
    echo -e "[INFO] Reloading firewall-cmd"
        firewall-cmd --reload
}

tier3() {
    echo -e "[INFO] Installing database server on ${hostname}"
}

nfs() {
    echo -e "[INFO] Installing nfs server on ${hostname}"
}

update_packages

case ${hostname} in

    tier1-webserver.local.com)
        tier1
        ;;
    tier2-app1.local.com | tier2-app2.local.com)
        tier2
        ;;
    tier3-db.local.com)
        tier3
        ;;
    nfs.local.com)
        nfs
        ;;
        *)
        echo -e "[INFO] No command..."

esac