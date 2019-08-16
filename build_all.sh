PATH="${PWD}/ruby-build/bin:$PATH"

VERSIONS=$(ruby-build --definitions | grep "^${PREFIX}" | grep -v dev)
OS=$(uname -s)
ARCH=$(uname -m) 
if [ -z ${OS_VERSION} ]; then 
  OS_VERSION=$(uname -r)

  if [ "${OS}" == "Linux" ]; then 
    OS_VERSION="all"
  fi
fi

mkdir -p ./archives 
echo "Versions: ${VERSIONS}"
export DEFAULT_CONFIGURE_OPTS="--disable-install-doc --enable-load-relative"

pip install -r requirements.txt

FAILED=()
SUCCESSFUL=()
BUILD_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
for i in ${VERSIONS}; do
  RUBY_DIR="${BUILD_DIR}/$i"
  TARFILE="ruby-$i-$OS-$ARCH-$OS_VERSION.tar.bz2"
  IN_S3=$(curl -s -I https://yourbase-build-tools.s3-us-west-2.amazonaws.com/ruby/$TARFILE | grep 200)
  if [ "$?" == "0" ]; then 
    echo "$TARFILE already exists in S3!"
  else 
    if [ ! -d ${RUBY_DIR} ]; then
      echo "Will build Ruby $i..."
      mkdir -p $i
      RUBY_CONFIGURE_OPTS="${DEFAULT_CONFIGURE_OPTS}"

      if [[ "$i" =~ "2.1" ]] || [[ "$i" =~ "2.0" ]] || [[ "$i" =~ "2.2" ]] || [[ "$i" =~ "2.3" ]]; then 
        echo "Installing OpenSSL 1.0 into ${RUBY_DIR}"
        wget https://www.openssl.org/source/openssl-1.0.2s.tar.gz
        tar zxvf openssl-1.0.2s.tar.gz
        (cd openssl-1.0.2s && ./config -fPIC --openssldir=${RUBY_DIR} --prefix=${RUBY_DIR} && make && make install) 
        if [ "$?" != "0" ]; then 
          echo "Failed to install OpenSSL 1.0, will try next Ruby version"
          continue
        fi

        RUBY_CONFIGURE_OPTS="${RUBY_CONFIGURE_OPTS} --with-openssl-dir=${RUBY_DIR} --with-gcc=gcc"
      fi 

      ruby-build $i ${RUBY_DIR}
      if [ "$?" == "0" ]; then 
        echo "Successfully built Ruby v${i}"
        SUCCESSFUL+=( "$i" )
        OUTFILE="./archives/${TARFILE}"
        echo "Done! Compressing $i as $OUTFILE..."
        tar jcf ${OUTFILE} ${i}
        # Sync after successful build in case of partial failure
        aws s3 sync ./archives/ s3://yourbase-build-tools/ruby/ --acl public-read --no-progress
      else   
        echo "Failed to build Ruby v${i}"
        FAILED+=( "$i" )
      fi
    else
      echo "Already built $i"
    fi
  fi 
done

