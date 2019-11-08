#!/bin/bash

set -ex

[ -n "${ANDROID_NDK}" ]

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

apt-get update
apt-get install -y --no-install-recommends autotools-dev autoconf unzip
apt-get autoclean && apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

pushd /tmp
curl -Os https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK}-linux-x86_64.zip
popd
_ndk_dir=/opt/ndk
mkdir -p "$_ndk_dir"
unzip -qo /tmp/android*.zip -d "$_ndk_dir"
_versioned_dir=$(find "$_ndk_dir/" -mindepth 1 -maxdepth 1 -type d)
mv "$_versioned_dir"/* "$_ndk_dir"/
rmdir "$_versioned_dir"
rm -rf /tmp/*

# Installing android sdk
# https://github.com/circleci/circleci-images/blob/staging/android/Dockerfile.m4

_sdk_version=sdk-tools-linux-3859397.zip
_android_home=/opt/android/sdk

rm -rf $_android_home
sudo mkdir -p $_android_home
curl --silent --show-error --location --fail --retry 3 --output /tmp/$_sdk_version https://dl.google.com/android/repository/$_sdk_version
sudo unzip -q /tmp/$_sdk_version -d $_android_home
rm /tmp/$_sdk_version

sudo chmod -R 777 $_android_home

export ANDROID_HOME=$_android_home
export ADB_INSTALL_TIMEOUT=120

export PATH="${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}"
echo "PATH:${PATH}"
alias sdkmanager="$ANDROID_HOME/tools/bin/sdkmanager"

sudo mkdir ~/.android && sudo echo '### User Sources for Android SDK Manager' > ~/.android/repositories.cfg
sudo chmod -R 777 ~/.android

yes | sdkmanager --licenses
yes | sdkmanager --update

sdkmanager \
  "tools" \
  "platform-tools" \
  "emulator"

sdkmanager \
  "build-tools;28.0.3" \
  "build-tools;29.0.2"

sdkmanager \
  "platforms;android-28" \
  "platforms;android-29"
sdkmanager --list

# Installing Gradle
echo "GRADLE_VERSION:${GRADLE_VERSION}"
_gradle_home=/opt/gradle
sudo rm -rf $gradle_home
sudo mkdir -p $_gradle_home

wget --no-verbose --output-document=/tmp/gradle.zip \
"https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

sudo unzip -q /tmp/gradle.zip -d $_gradle_home
rm /tmp/gradle.zip

sudo chmod -R 777 $_gradle_home

export GRADLE_HOME=$_gradle_home/gradle-$GRADLE_VERSION
alias gradle="${GRADLE_HOME}/bin/gradle"

export PATH="${GRADLE_HOME}/bin/:${PATH}"
echo "PATH:${PATH}"

gradle --version
