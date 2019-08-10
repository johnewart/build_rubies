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
export CONFIGURE_OPTS="--disable-install-doc --enable-load-relative"

for i in ${VERSIONS}; do
  TARFILE="ruby-$i-$OS-$ARCH-$OS_VERSION.tar.bz2"
  IN_S3=$(curl -s -I https://yourbase-build-tools.s3-us-west-2.amazonaws.com/ruby/$TARFILE | grep 200)
  if [ "$?" == "0" ]; then 
    echo "$TARFILE already exists in S3!"
  else 
    if [ ! -d ./$i ]; then
      echo "Will build $i..."
      ruby-build $i ./$i
    else
      echo "Already built $i"
    fi

    OUTFILE="./archives/${TARFILE}"
    echo "Compressing $i as $TARFILE..."
    tar jcf ${OUTFILE} ${i}
  fi 
done

pip install -r requirements.txt
aws s3 sync ./archives/ s3://yourbase-build-tools/ruby/ --acl public-read --no-progress
