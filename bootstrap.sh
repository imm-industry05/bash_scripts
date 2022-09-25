#!/bin/bash -xe

hostname=`hostname`
ipv4=`hostname -I`
jumpserver="192.168.0.250\/32"



update_packages() {
    echo -e "[INFO] Updating the machine ${hostname}"
        yum update -y

    echo -e "[INFO] Install necessary packages...."
        yum install -y epel-release git nfs-utils

    echo -e "[INFO] Cloning bash_scripts configuration"
        rm -rf bash_scripts
        git clone https://github.com/imm-industry05/bash_scripts.git bash_scripts
        sed "s/ip-hosts/${ipv4} ${hostname}/g"  bash_scripts/hosts
        cat bash_scripts/hosts > /etc/hosts
        
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
    

    echo -e "[INFO] Allowing http and https service."
        firewall-cmd --zone=public --permanent --add-service=https
        firewall-cmd --zone=public --permanent --add-service=http

    echo -e "[INFO] Allowing port 80 and 443."
        firewall-cmd --zone=public --permanent --add-port=80/tcp
        firewall-cmd --zone=public --permanent --add-port=443/tcp
    
    echo -e "[INFO] Reloading firewall-cmd"
        firewall-cmd --reload

    echo -e "[INFO] Sending notification...."
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"CPE-301: WebServer with hostname: ${hostname} and ip: ${ipv4} is up and running.\"}" ${webhook}
}

tier2() {
    echo -e "[INFO] Install httpd on ${hostname}"
        yum install -y httpd
    
    echo -e "[INFO] Allowing http and https service."
        firewall-cmd --zone=public --permanent --add-service=https
        firewall-cmd --zone=public --permanent --add-service=http

    echo -e "[INFO] Allowing port 80 and 443."
        firewall-cmd --zone=public --permanent --add-port=80/tcp
        firewall-cmd --zone=public --permanent --add-port=8080/tcp
        firewall-cmd --zone=public --permanent --add-port=443/tcp
        firewall-cmd --zone=public --permanent --add-port=8443/tcp
    
    echo -e "[INFO] Reloading firewall-cmd"
        firewall-cmd --reload

    echo -e "[INFO] Sending notification...."
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"CPE-301: Application Server with hostname: ${hostname} and ip: ${ipv4} is up and running.\"}" ${webhook}
}

tier3() {
    echo -e "[INFO] Installing database server on ${hostname}"
        yum install -y mariadb-server

    echo -e "[INFO] Set mariadb-server to start on boot"
        systemctl enable mariadb

    echo -e "[INFO] Starting mariadb-server server"
        systemctl start mariadb
    

    echo -e "[INFO] Allowing MySQL Ports."
        firewall-cmd --zone=public --permanent --add-port=3306/tcp
    
    echo -e "[INFO] Reloading firewall-cmd"
        firewall-cmd --reload

    echo -e "[INFO] Sending notification...."
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"CPE-301: Database Server with hostname: ${hostname} and ip: ${ipv4} is up and running.\"}" ${webhook}
}

nfs() {
    echo -e "[INFO] Installing nfs server on ${hostname}"
        yum install -y nfs-utils
    
    echo -e  "[INFO] Set nfs services to start on boot"
        systemctl enable rpcbind
        systemctl enable nfs-server
        systemctl enable nfs-lock
        systemctl enable nfs-idmap
    
    echo -e  "[INFO] Starting nfs services"
        systemctl start rpcbind
        systemctl start nfs-server
        systemctl start nfs-lock
        systemctl start nfs-idmap


    echo -e "[INFO] Allowing http and https service."
        firewall-cmd --permanent --zone=public --add-service=nfs
        firewall-cmd --permanent --zone=public --add-service=mountd
        firewall-cmd --permanent --zone=public --add-service=rpc-bind
    
    echo -e "[INFO] Reloading firewall-cmd"
        firewall-cmd --reload

    echo -e "[INFO] Sending notification...."
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"CPE-301: NFS Server with hostname: ${hostname} and ip: ${ipv4} is up and running.\"}" ${webhook}
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