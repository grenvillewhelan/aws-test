#!/bin/bash

CLOUD_PLATFORM=$(cat /opt/AIL/.cloud_platform)

if [ -f /opt/AIL/tools/utils.sh ]; then
   . /opt/AIL/tools/utils.sh
else
   echo "$0: Cannot read /opt/AIL/tools/utils.sh, exiting."
   exit 1
fi

export cloud_provider=${CLOUD_PROVIDER}
export cloud_providers=$(jq -n ${CLOUD_PROVIDERS} | jq -r '. | join(" ")')
server_number=${SERVER_INSTANCE}
export LOC_DIR="/opt/openam"

echo "$0: running pingam.sh $*"

if [ ! -d "${LOC_DIR}" ]; then
  echo "$0: cannot locate ${LOC_DIR}"
fi

PD_USER="ubuntu"
chown -R "${PD_USER}:${PD_USER}" ${LOC_DIR}

echo "Running PingAM setup"
echo

echo "Installing tomcat-10"

sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat
wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.34/bin/apache-tomcat-10.1.34.tar.gz
sudo mkdir -p /opt/tomcat
sudo tar -xf apache-tomcat-10.1.34.tar.gz -C /opt/tomcat --strip-components=1
sudo chown -R tomcat:tomcat /opt/tomcat
sudo chmod -R +x /opt/tomcat/bin
sudo cp /opt/openam/AM-8.0.2.war /opt/tomcat/webapps/am.war


sudo bash -c 'cat <<EOT > /opt/tomcat/bin/setenv.sh
export CATALINA_OPTS="\$CATALINA_OPTS -Xms2g -Xmx2g -Djava.awt.headless=true \
 --add-opens=java.base/java.lang=ALL-UNNAMED \
 --add-opens=java.base/java.util=ALL-UNNAMED \
 --add-opens=java.base/java.util.concurrent=ALL-UNNAMED \
 --add-opens=java.base/java.io=ALL-UNNAMED \
 --add-opens=java.base/sun.net.www.protocol.jar=ALL-UNNAMED \
 --add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED"
EOT'

sudo bash <<'EOT'

echo '[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target ' >> /etc/systemd/system/tomcat.service
EOT

sudo chown -R tomcat:tomcat /opt/tomcat
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat

echo "${VERSION}" > ${LOC_DIR}/.version
update_name_tag "${SERVER_TYPE}-running"


echo "$0: Completed at $(date)"
