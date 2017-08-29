cd /opt/splunk
aws s3 cp s3://splunkjpp/splunk-app-for-aws_502.tgz /opt/splunk/etc/apps/splunk-app-for-aws_502.tgz
tar -C /opt/splunk/etc/apps -xvzf /opt/splunk/etc/apps/splunk-app-for-aws_502.tgz
/opt/splunk/bin/splunk restart

