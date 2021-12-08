#!/bin/bash

set -e

echo "Started with args"

work_dir="$work_dir"

client_version_env="$client_version_env" #We should pick this from the jar not as an argument.
crypto_key_env="$crypto_key_env" #key to encrypt the jar files
client_certificate="$client_certificate_env" # Not used as of now
client_upgrade_server="$client_upgrade_server_env" #docker hosted url
reg_client_sdk_url="$reg_client_sdk_url_env"
artifactory_url="$artifactory_url_env"

echo "initalized variables"

echo "environment=${host_name_env}" > "${work_dir}"/mosip-application.properties
echo "mosip.reg.app.key=${crypto_key_env}" > "${work_dir}"/mosip-application.properties
echo "mosip.reg.version=${client_version_env}" >> "${work_dir}"/mosip-application.properties
echo "mosip.reg.client.url=${client_upgrade_server}/registration-client/" >> "${work_dir}"/mosip-application.properties
echo "mosip.reg.healthcheck.url=${healthcheck_url_env}" >> "${work_dir}"/mosip-application.properties
echo "mosip.reg.rollback.path=../BackUp" >> "${work_dir}"/mosip-application.properties
echo "mosip.reg.cerpath=/cer/mosip_cer.cer" >> "${work_dir}"/mosip-application.properties
echo "mosip.reg.dbpath=db/reg" >> "${work_dir}"/mosip-application.properties
echo "mosip.reg.xml.file.url=${client_upgrade_server}/registration-client/maven-metadata.xml" >> "${work_dir}"/mosip-application.properties
echo "mosip.reg.client.tpm.availability=Y" >> "${work_dir}"/mosip-application.properties
echo "mosip.client.upgrade.server.url=${client_upgrade_server}" >> "${work_dir}"/mosip-application.properties
echo "mosip.hostname=${host_name_env}"  >> "${work_dir}"/mosip-application.properties

echo "created mosip-application.properties"

cd "${work_dir}"/registration-client/target/lib
mkdir -p ${work_dir}/registration-client/target/lib/props
cp "${work_dir}"/mosip-application.properties ${work_dir}/registration-client/target/lib/props/mosip-application.properties
jar uf registration-services-${client_version_env}.jar props/mosip-application.properties
rm -rf ${work_dir}/registration-client/target/lib/props

cd "${work_dir}"

if wget "${artifactory_url}/artifactory/libs-release-local/reg-client/resources.zip"
then
  echo "Successfully downloaded reg-client resources, Adding it to reg-client jar"
  mkdir resources
  /usr/bin/unzip ./resources.zip -d ./resources/
  cd ./resources
  jar uvf "${work_dir}"/registration-client/target/registration-client-${client_version_env}.jar .
else
  echo "No separate resources found !!"
fi

cd "${work_dir}"
mkdir -p "${work_dir}"/sdkjars

if [ "$reg_client_sdk_url" ]
then
	echo "Found thirdparty SDK"
	wget "$reg_client_sdk_url"
	/usr/bin/unzip "${work_dir}"/sdkDependency.zip
	cp "${work_dir}"/sdkDependency/*.jar "${work_dir}"/registration-client/target/lib/
else
	echo "Downloading MOCK SDK..."
	wget "${artifactory_url}/artifactory/libs-release-local/mock-sdk/1.1.5/mock-sdk.jar" -O "${work_dir}"/registration-client/target/lib/mock-sdk.jar
fi

wget "${artifactory_url}/artifactory/libs-release-local/icu4j/icu4j.jar" -O "${work_dir}"/registration-client/target/lib/icu4j.jar
wget "${artifactory_url}/artifactory/libs-release-local/icu4j/kernel-transliteration-icu4j.jar" -O "${work_dir}"/registration-client/target/lib/kernel-transliteration-icu4j.jar
wget "${artifactory_url}/artifactory/libs-release-local/clamav/clamav.jar" -O "${work_dir}"/registration-client/target/lib/clamav.jar
wget "${artifactory_url}/artifactory/libs-release-local/clamav/kernel-virusscanner-clamav.jar" -O "${work_dir}"/registration-client/target/lib/kernel-virusscanner-clamav.jar

#unzip Jre to be bundled
wget "${artifactory_url}/artifactory/libs-release-local/zulu11.41.23-ca-fx-jre11.0.8-win_x64.zip" -O "${work_dir}"/zulu11.41.23-ca-fx-jre11.0.8-win_x64.zip
/usr/bin/unzip "${work_dir}"/zulu11.41.23-ca-fx-jre11.0.8-win_x64.zip
mkdir -p "${work_dir}"/registration-client/target/jre
mv "${work_dir}"/zulu11.41.23-ca-fx-jre11.0.8-win_x64/* "${work_dir}"/registration-client/target/jre/
chmod -R a+x "${work_dir}"/registration-client/target/jre

cp "${work_dir}"/build_files/logback.xml "${work_dir}"/registration-client/target/lib/logback.xml
cp "${work_dir}"/registration-client/target/registration-client-${client_version_env}.jar "${work_dir}"/registration-client/target/lib/registration-client-${client_version_env}.jar
/usr/local/openjdk-11/bin/java -cp "${work_dir}"/registration-client/target/registration-client-${client_version_env}.jar:"${work_dir}"/registration-client/target/lib/* io.mosip.registration.update.ManifestCreator "${client_version_env}" "${work_dir}/registration-client/target/lib" "${work_dir}/registration-client/target"

cd "${work_dir}"/registration-client/target/

echo "Started to create the registration client zip"

ls -ltr lib | grep bc

echo "@echo OFF" >> run.bat
echo "start jre\jre\bin\javaw -Xmx2048m -Xms2048m -Dfile.encoding=UTF-8 -cp lib/*;/* io.mosip.registration.controller.Initialization > logs/startup.log 2>&1" > run.bat

/usr/bin/zip -r reg-client.zip jre
/usr/bin/zip -r reg-client.zip lib
/usr/bin/zip -r reg-client.zip MANIFEST.MF
/usr/bin/zip -r reg-client.zip run.bat

#Creating client testing utility
mkdir -p "${work_dir}"/registration-test-utility
mkdir -p "${work_dir}"/registration-test-utility/lib
cp "${work_dir}"/registration-test/target/registration-test-${client_version_env}.jar "${work_dir}"/registration-test-utility/registration-test.jar
cp -r "${work_dir}"/registration-test/target/lib/* "${work_dir}"/registration-test-utility/lib
## override with updated jars
cp -r "${work_dir}"/registration-client/target/lib/* "${work_dir}"/registration-test-utility/lib
cp -r "${work_dir}"/registration-test/resources/*  "${work_dir}"/registration-test-utility/
cp -r "${work_dir}"/registration-client/target/jre "${work_dir}"/registration-test-utility/
cp "${work_dir}"/registration-client/target/MANIFEST.MF "${work_dir}"/registration-test-utility/

cd "${work_dir}"
/usr/bin/zip -r ./registration-test-utility.zip ./registration-test-utility/*

echo "setting up nginx static content"

mkdir -p /var/www/html/registration-client
mkdir -p /var/www/html/registration-client/${client_version_env}
mkdir -p /var/www/html/registration-client/${client_version_env}/lib
mkdir -p /var/www/html/registration-test/${client_version_env}
 
cp "${work_dir}"/registration-client/target/lib/* /var/www/html/registration-client/${client_version_env}/lib
cp "${work_dir}"/registration-client/target/MANIFEST.MF /var/www/html/registration-client/${client_version_env}/
cp "${work_dir}"/build_files/maven-metadata.xml /var/www/html/registration-client/
cp "${work_dir}"/registration-client/target/reg-client.zip /var/www/html/registration-client/${client_version_env}/
cp "${work_dir}"/registration-test-utility.zip /var/www/html/registration-client/${client_version_env}/

echo "setting up nginx static content - completed"

/usr/sbin/nginx -g "daemon off;"
