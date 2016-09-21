# -*- mode: ruby -*-
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "4096"
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y clang-3.8 llvm-3.8 libclang-3.8-dev g++ make cmake build-essential libatlas-base-dev python python-pip libpython-dev m4 libprotobuf-dev protobuf-compiler python-protobuf python-numpy git libgoogle-glog-dev libgflags-dev libgtest-dev
    sudo pip install wheel
    sudo chmod -R a+w /usr/src/gtest
    cd /usr/src/gtest
    cmake . && make
    sudo cp *.a /usr/lib

    cd /vagrant
    if [[ ! -d woboq_codebrowser ]]; then
        git clone https://github.com/woboq/woboq_codebrowser
    fi
    cd woboq_codebrowser
    git checkout master
    git pull origin master
    cmake . -DLLVM_CONFIG_EXECUTABLE=/usr/bin/llvm-config-3.8 -DCMAKE_BUILD_TYPE=Release
    make -j4

    cd /vagrant
    if [[ ! -d paddle ]]; then
        git clone https://github.com/baidu/paddle
    fi
    cd paddle
    git checkout master
    git pull origin master
    if [[ -f Makefile ]]; then
        make clean
    fi
    rm CMakeCache.txt
    cmake . -DWITH_GPU=OFF -DWITH_DOC=OFF -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    make -j4

    export OUTPUTDIRECTORY=/vagrant/paddle_html/codebrowser
    cp -rv /vagrant/woboq_codebrowser/data /vagrant/paddle_html/
    BUILDIRECTORY=$PWD
    VERSION=`git describe --always --tags`
    /vagrant/woboq_codebrowser/generator/codebrowser_generator -b $BUILDIRECTORY -a -o $OUTPUTDIRECTORY -p codebrowser:$BUILDIRECTORY:$VERSION
    /vagrant/woboq_codebrowser/indexgenerator/codebrowser_indexgenerator $OUTPUTDIRECTORY
  SHELL
end
