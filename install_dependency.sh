#!/bin/bash
set -e

echo "Unzip core files"
cd clash.meta
ls
gzip -d *.gz
echo "Create Universal core"
lipo -create -output com.metacubex.ClashX.ProxyConfigHelper.meta clash.meta-darwin-amd64* clash.meta-darwin-arm64*
chmod +x com.metacubex.ClashX.ProxyConfigHelper.meta

echo "Update meta core md5 to code"
sed -i '' "s/WOSHIZIDONGSHENGCHENGDEA/$(md5 -q com.metacubex.ClashX.ProxyConfigHelper.meta)/g" ../ClashX/AppDelegate.swift
sed -n '20p' ../ClashX/AppDelegate.swift

echo "Gzip Universal core"
gzip com.metacubex.ClashX.ProxyConfigHelper.meta
cp com.metacubex.ClashX.ProxyConfigHelper.meta.gz ../ClashX/Resources/
cd ..

echo "Pod install"
pod install
echo "delete old files"
rm -f ./ClashX/Resources/country.mmdb
rm -f ./ClashX/Resources/geosite.dat
rm -f ./ClashX/Resources/geoip.dat
rm -rf ./ClashX/Resources/dashboard
rm -f GeoLite2-Country.*
echo "install mmdb"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb
gzip country.mmdb
mv country.mmdb.gz ./ClashX/Resources/country.mmdb.gz
echo "install geosite"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
gzip geosite.dat
mv geosite.dat.gz ./ClashX/Resources/geosite.dat.gz
echo "install geoip"
curl -LO https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat
gzip geoip.dat
mv geoip.dat.gz ./ClashX/Resources/geoip.dat.gz
echo "install dashboard"
cd ClashX/Resources
git clone -b gh-pages https://github.com/MetaCubeX/yacd.git dashboard
