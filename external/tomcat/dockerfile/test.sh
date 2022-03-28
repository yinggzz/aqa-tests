#/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

source $(dirname "$0")/test_base_functions.sh
#Set up Java to be used by the tomcat test
echo_setup

ARCH=`uname -p`
echo $ARCH
JDK_X64="https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jdk_x64_linux_hotspot_11.0.11_9.tar.gz"
JDK_ARM64="https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.11_9.tar.gz"
JDK_s390x="https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jdk_s390x_linux_hotspot_11.0.11_9.tar.gz"
JDK_ppc64le="https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.11%2B9/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.11_9.tar.gz"
if test "X$ARCH" = "Xaarch64"; then JDK_URL=$JDK_ARM64; elif test "$ARCH" = "ppc64le"; then JDK_URL=$JDK_ppc64le; elif test "$ARCH" = "s390x"; then JDK_URL=$JDK_s390x; else JDK_URL=$JDK_X64; fi
wget -q $JDK_URL && tar xzf OpenJDK*.tar.gz
mv jdk-11* jdk
export JAVA_HOME=`pwd`/jdk
wget -q https://mirrors.netix.net/apache/ant/binaries/apache-ant-1.10.11-bin.tar.gz && tar xzf apache-ant-*-bin.tar.gz
export ANT_HOME=`pwd`/apache-ant-1.10.11
export PATH="$JAVA_HOME/bin:$ANT_HOME/bin:$PATH"
java -version
ant -version
rm -rf $HOME/tmp
export CURR_PWD=`pwd`
git clone -q -b 1.6.x --single-branch https://github.com/apache/apr.git $HOME/tmp/apr
cd $HOME/tmp/apr
./buildconf
./configure --prefix=$HOME/tmp/apr-build
make
make install
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/tmp/apr-build/lib"
git clone -q https://github.com/apache/tomcat-native.git $HOME/tmp/tomcat-native
cd $HOME/tmp/tomcat-native/native
sh buildconf --with-apr=$HOME/tmp/apr
./configure --with-apr=$HOME/tmp/apr --with-java-home=$JAVA_HOME --with-ssl=yes --prefix=$HOME/tmp/tomcat-native-build
make
make install
cd $CURR_PWD
yes | cp build.properties.default build.properties
echo >> build.properties
echo "test.threads=4" >> build.properties
echo "test.relaxTiming=true" >> build.properties
echo "test.excludePerformance=true" >> build.properties
echo "test.openssl.path=/dev/null/openssl" >> build.properties
echo "test.apr.loc=$HOME/tmp/tomcat-native-build/lib" >> build.properties

set -e
echo "Building tomcat" && \
cp build.properties.default build.properties && \
ant && \

echo "Running tomcat tests" 
#Run tests
ant test
set +e
