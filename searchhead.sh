#!/bin/bash
yum update -y
cd /opt
wget -O splunk-6.6.3-e21ee54bc796-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=6.6.3&product=splunk&filename=splunk-6.6.3-e21ee54bc796-linux-2.6-x86_64.rpm&wget=true'
sleep 5
sudo useradd -b /home -c "Splunk dedicated user" --user-group --create-home -s "/bin/bash" splunk
cat <<EOF |sudo -u splunk tee -a /home/splunk/.bashrc
alias ll='ls -lrt'
export PATH=\$PATH:/opt/splunk/bin
cd /opt/splunk/etc
EOF
rpm -ivh splunk-6.6.3-e21ee54bc796-linux-2.6-x86_64.rpm
sudo chown -R splunk:splunk /opt/splunk

cd /opt/splunk/etc/system/local
cat <<EOF |sudo -u splunk tee -a /opt/splunk/etc/system/local/server.conf
[clustering]
mode = searchhead
master_uri = https://172.31.5.39:8089
pass4SymmKey = udemy
EOF

# Update hostname
hostname splunk-`hostname`
echo `hostname` > /etc/hostname
sed -i 's/localhost$/localhost '`hostname`'/' /etc/hosts


# Start service and Enable autostart
sudo -u splunk /opt/splunk/bin/splunk enable boot-start -user splunk --accept-license
sudo -u splunk /opt/splunk/bin/splunk start --accept-license
