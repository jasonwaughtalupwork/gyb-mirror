if [ "$VMTYPE" == "test" ]; then
  export python="python"
  export pip="pip"
  echo "Travis setup Python $TRAVIS_PYTHON_VERSION"
  echo "running tests with this version"
else
  export whereibelong=$(pwd)
  export dist=$(lsb_release --codename --short)
  echo "We are running on Ubuntu $dist"
  echo "RUNNING: apt update..."
  sudo apt-get -qq --yes update > /dev/null
  echo "RUNNING: apt dist-upgrade..."
  sudo apt-get -qq --yes dist-upgrade > /dev/null
  echo "Installing build tools..."
  sudo apt-get -qq --yes install build-essential > /dev/null

  echo "Installing deps for python3"
  sudo cp -v /etc/apt/sources.list /tmp
  sudo chmod a+rwx /tmp/sources.list
  echo "deb-src http://archive.ubuntu.com/ubuntu/ $dist main" >> /tmp/sources.list
  sudo cp -v /tmp/sources.list /etc/apt
  sudo apt-get -qq --yes update > /dev/null
  sudo apt-get -qq --yes build-dep python3 > /dev/null

  mypath=$HOME
  echo "My Path is $mypath"
  cpucount=$(nproc --all)
  echo "This device has $cpucount CPUs for compiling..."

  cd ~/pybuild
  # Compile latest OpenSSL
  if [ ! -d openssl-$BUILD_OPENSSL_VERSION ]; then
    wget --quiet https://www.openssl.org/source/openssl-$BUILD_OPENSSL_VERSION.tar.gz
    echo "Extracting OpenSSL $BUILD_OPENSSL_VERSION..."
    tar xf openssl-$BUILD_OPENSSL_VERSION.tar.gz
  fi
  cd openssl-$BUILD_OPENSSL_VERSION
  echo "Compiling OpenSSL $BUILD_OPENSSL_VERSION..."
  ./config shared --prefix=$mypath/ssl
  echo "Running make for OpenSSL..."
  make -j$cpucount -s
  echo "Running make install for OpenSSL..."
  make install > /dev/null
  export LD_LIBRARY_PATH=~/ssl/lib
  cd ~/pybuild

  # Compile latest Python
  if [ ! -d Python-$BUILD_PYTHON_VERSION ]; then
    curl -O https://www.python.org/ftp/python/$BUILD_PYTHON_VERSION/Python-$BUILD_PYTHON_VERSION.tar.xz
    echo "Extracting Python..."
    tar xf Python-$BUILD_PYTHON_VERSION.tar.xz
  fi
  cd Python-$BUILD_PYTHON_VERSION
  echo "Compiling Python $BUILD_PYTHON_VERSION..."
  safe_flags="--with-openssl=$mypath/ssl --enable-shared --prefix=$mypath/python --with-ensurepip=upgrade"
  unsafe_flags="--enable-optimizations --with-lto"
  if [ ! -e Makefile ]; then
    ./configure $safe_flags # $unsafe_flags > /dev/null
  fi
  make -j$cpucount -s
  RESULT=$?
  echo "First make exited with $RESULT"
  if [ $RESULT != 0 ]; then
    echo "Trying Python $BUILD_PYTHON_VERSION compile again without unsafe flags"
    make clean
    ./configure $safe_flags > /dev/null
    make -j$cpucount -s
  fi
  echo "Installing Python..."
  make install > /dev/null
  cd ~

  export LD_LIBRARY_PATH=~/ssl/lib:~/python/lib
  export python=~/python/bin/python3
  export pip=~/python/bin/pip3

  $python -V

  if [[ "$dist" == "precise" ]]; then
    echo "Installing deps for StaticX..."
    sudo apt-get install --yes scons
    if [ ! -d patchelf-$PATCHELF_VERSION ]; then
      echo "Downloading PatchELF $PATCHELF_VERSION"
      wget https://nixos.org/releases/patchelf/patchelf-$PATCHELF_VERSION/patchelf-$PATCHELF_VERSION.tar.bz2
      tar xf patchelf-$PATCHELF_VERSION.tar.bz2
      cd patchelf-$PATCHELF_VERSION
      ./configure
      make
      sudo make install
    fi
    $pip install git+https://github.com/JonathonReinhart/staticx.git@master
  fi

  echo "Upgrading pip packages..."
  $pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 $pip install -U
  $pip install -r requirements.txt
  $pip install pyinstaller

  cd $whereibelong
fi
