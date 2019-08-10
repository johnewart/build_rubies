PATH="${PWD}/ruby-build/bin:$PATH"

ruby-build --definitions

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
export CONFIGURE_OPTS="--disable-install-doc --enable-load-relative"

for i in ${VERSIONS}; do
  if [ ! -d ./$i ]; then
    echo "Will build $i..."
    ruby-build $i ./$i
  else
    echo "Already built $i"
  fi

  TARFILE="./archives/ruby-$i-$OS-$ARCH-$OS_VERSION.tar.bz2"
  echo "Compressing $i as $TARFILE..."
  tar jcf ${TARFILE} ${i}
done

pip install -r requirements.txt
aws s3 sync ./archives/ s3://yourbase-build-tools/ruby/ --acl public-read
