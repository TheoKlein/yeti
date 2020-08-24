# Install dependencies
export LC_ALL="en_US.UTF-8"

if [ -f "/usr/bin/apt" ]; then
   APT="/usr/bin/apt"
else
   APT="/usr/bin/apt-get"
fi

$APT update -y
$APT install apt-transport-https dirmngr

curl -sL https://deb.nodesource.com/setup_10.x | bash -
$APT install nodejs -y

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
# apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4

# https://www.debian.org/releases/
OS_CODENAME=`lsb_release -c --short`

if [ $OS_CODENAME == "stretch" ]; then
  wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | sudo apt-key add -
  echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.0 main" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list
elif [ $OS_CODENAME == "jessie" ]; then
  wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | sudo apt-key add -
  echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/4.0 main" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list
elif [ $OS_CODENAME == "buster" ]; then
  wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
  echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
else
  wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | sudo apt-key add -
  echo "[!] Installing on an unsupported or outdated version of Debian, trying Jessie package for Mongo"
  echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/4.0 main" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list
fi

$APT update -y
$APT install build-essential git python3-dev mongodb-org redis-server libcurl4 libxml2-dev libxslt1-dev zlib1g-dev python3-virtualenv python3-pip nginx yarn -y

# Clone project
cd /opt
git clone https://github.com/TheoKlein/yeti.git

# Install requirements
cd /opt/yeti
pip3 install -U pip
pip3 install -r requirements.txt
pip3 install uwsgi
yarn install

# Configure services
useradd yeti
sudo mkdir /var/log/yeti
sudo chown yeti /var/log/yeti
cp extras/systemd/*.service /etc/systemd/system/
systemctl enable mongod.service
systemctl enable yeti_uwsgi.service
systemctl enable yeti_oneshot.service
systemctl enable yeti_feeds.service
systemctl enable yeti_exports.service
systemctl enable yeti_analytics.service
systemctl enable yeti_beat.service
systemctl enable yeti_web.service
systemctl daemon-reload
chown -R yeti:yeti /opt/yeti
chmod +x /opt/yeti/yeti.py

# Configure nginx
rm /etc/nginx/sites-enabled/default
cp extras/nginx/yeti /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/yeti /etc/nginx/sites-enabled/yeti
service nginx restart

# Start services
echo "[+] Starting services..."
systemctl start mongod.service
systemctl start yeti_oneshot.service
sleep 5
systemctl start yeti_feeds.service
systemctl start yeti_exports.service
systemctl start yeti_analytics.service
systemctl start yeti_beat.service
systemctl start yeti_uwsgi.service
systemctl start yeti_web.service

echo "[+] Yeti succesfully installed. Webserver listening on tcp/80"
