VERSIONS=$(ruby-build --definitions | grep "^${PREFIX}")

for i in ${VERSIONS}; do
  if [ ! -d ./$i ]; then
    echo "Will build $i..."
    ruby-build $i ./$i
  else
    echo "Already built $i"
  fi
done
