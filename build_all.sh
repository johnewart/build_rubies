if [ -z "${AWS_ACCESS_KEY_ID}" ]; then 
  echo "No AWS credentials present, you need to set them so the images can be uploaded"
  exit 
fi 

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
