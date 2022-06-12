#!/bin/bash
set -e
echo "Build Clash core"

cd ClashX/goClash
python3 build_clash_universal.py
cd ../..

echo "Pod install"
bundle install --jobs 4
bundle exec pod install
echo "delete old files"
rm -f ./ClashX/Resources/Country.mmdb
rm -f ./ClashX/Resources/geosite.dat
rm -f ./ClashX/Resources/geoip.dat
rm -rf ./ClashX/Resources/dashboard
rm -f GeoLite2-Country.*
echo "install mmdb"
curl -LO https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb
gzip Country.mmdb
mv Country.mmdb.gz ./ClashX/Resources/Country.mmdb.gz
echo "install geosite"
curl -LO https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
gzip geosite.dat
mv geosite.dat.gz ./ClashX/Resources/geosite.dat.gz
echo "install geoip"
curl -LO https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
gzip geoip.dat
mv geoip.dat.gz ./ClashX/Resources/geoip.dat.gz
echo "install dashboard"
cd ClashX/Resources
git clone -b gh-pages https://github.com/MetaCubeX/yacd.git dashboard
