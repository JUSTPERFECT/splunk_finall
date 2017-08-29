cd /opt/splunk
aws s3 cp s3://splunkjpp/splunk-add-on-for-amazon-web-services_430.tgz /opt/splunk/etc/apps/splunk-add-on-for-amazon-web-services_430.tgz
tar -C /opt/splunk/etc/apps -xvzf /opt/splunk/etc/apps/splunk-add-on-for-amazon-web-serv
ices_430.tgz
/opt/splunk/bin/splunk restart
