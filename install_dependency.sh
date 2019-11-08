#!/bin/bash
set -eu
echo "delete old files"
rm -f ./ClashXR/Resources/Country.mmdb
rm -rf ./ClashXR/Resources/dashboard
rm -f GeoLite2-Country.*
echo "install mmdb"
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz
tar -zxvf GeoLite2-Country.tar.gz
mv GeoLite2-Country_*/GeoLite2-Country.mmdb ./ClashXR/Resources/Country.mmdb
rm GeoLite2-Country.tar.gz
rm -r GeoLite2-Country_*
echo "install dashboard"
cd ClashXR/Resources
git clone -b gh-pages https://github.com/Dreamacro/clash-dashboard.git dashboard
cd ..