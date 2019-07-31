VERSIONS=$(ruby-build --definitions | grep "^${PREFIX}")
OS=$(uname -s)
ARCH=$(uname -m) 
VERSION=$(uname -r)

mkdir -p ./archives 

for i in ${VERSIONS}; do
  if [ ! -d ./$i ]; then
    echo "Will build $i..."
    ruby-build $i ./$i
  else
    echo "Already built $i"
  fi
  TARFILE="ruby-$i-$OS-$ARCH-$VERSION.tar.bz2"
  echo "Compressing $i as $TARFILE..."
  tar jcf ${TARFILE} ./archives/${i}
done
