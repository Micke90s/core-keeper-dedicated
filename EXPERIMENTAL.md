# README
This is just an experimental branch to test and develop the arm64 support. This branch will be extremely unstable.
I just will use it to create a more transparent approach. Also it will be used to deploy the current development to my Raspberry to speed up the tests. 
As soon as I get something stable i will update the `arm64-box64` branch. 


# Current tests
## 2024-11-15 Test with ubuntu
Ubuntu 24.04.1 LTS
```
  curl -sSL https://get.docker.com | sh
  git clone https://github.com/kelvin124124/core-keeper-dedicated.git
  cd core-keeper-dedicated/
  sudo docker compose up
```

Did not work, yet.

## 2024-11-15 Reset raspian
New image `2024-10-22-raspios-bookworm-arm64-lite`
```
  curl -sSL https://get.docker.com | sh
  git clone https://github.com/kelvin124124/core-keeper-dedicated.git
  cd core-keeper-dedicated/
  git checkout exp
  sudo docker build . --tag ck
  sudo docker compose up
```

## 2024-11-15 New branch by @kelvin124124
New idea by @kelvin124124 (https://github.com/kelvin124124/core-keeper-dedicated/tree/exp2)
based on `arm64v8/debian:bullseye-slim` and `DepotDownloader`
```
sudo docker build . --tag kelvin
sudo docker run --platform linux/arm64 -e BOX86_LD_LIBRARY_PATH=/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:/usr/lib/mono/x86_64-linux-gnu -e BOX64_LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/usr/lib/mono/amd64 -e PUID=1000 -e PGID=1000 kelvin
```
Result:
```
[S_API] SteamAPI_Init(): Loaded '/home/steam/.steam/sdk64/steamclient.so' OK.  (First tried local 'steamclient.so')
CAppInfoCacheReadFromDiskThread took 2 milliseconds to initialize
Setting breakpad minidump AppID = 1621690
[S_API FAIL] Tried to access Steam interface SteamNetworkingUtils004 before SteamAPI_Init succeeded.
Steam API initialized
Steam server API failed to log in anonymously
Thread "CHTTPClientThreadPool:0" (ID 141) failed to shut down
Thread "CHTTPClientThreadPool:0" (ID 141) failed to shut down
```
Need to reset raspian

## 2024-11-04 Prepare new test cases
* add `-extralog` parameter
* add infinite sleep for debugging

Tried to install extra components
```
apt-get update
apt-get install libxinerama1
apt-get install libmonosgen-2.0-1
apt-get install libatomic1
```

## 2024-11-02 Rebase
Rebase to current 2.0.0
(May not everything is clean at the moment, but it is the experimantal branch. `arm64-box64` will be updated later)

Faster startup by defining a volume for the program data:
```
sudo docker build . --tag ck
sudo docker volume create core
sudo docker run -v core:/home/steam/core-keeper-dedicated ck
```

## 2024-10-27 New branch
This is the new branch where I will put any information I am able to find. 
Also I will deploy any changes which will be part of my tests.

## 2024-10-11 Native installation on Raspberry
I tried to setup the DedicatedServer native on Raspian. I did not work. I got missing dependencies and version problems. 
I was not able to get steamCMD up and have to reset Raspian and start up from beginning. 

```
sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list
wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg 
sudo apt update && sudo apt install box64 -y

sudo wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg 
sudo apt update && sudo apt-get install box86-rpi4arm64:armhf -y

#git clone --branch v0.2.4 https://github.com/ptitSeb/box64.git
#cd box64
#cmake --build .

sudo apt -y install software-properties-common
sudo dpkg --add-architecture i386
sudo add-apt-repository -y -n -U http://deb.debian.org/debian -c non-free -c non-free-firmware
sudo apt update
sudo apt install steamcmd

wget --progress=dot:giga "https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_2.7.2/DepotDownloader-linux-arm64.zip" -O DepotDownloader.zip 
unzip DepotDownloader.zip
rm -rf DepotDownloader.xml
sudo chmod +x DepotDownloader
sudo mv DepotDownloader /usr/local/bin/DepotDownloader

DepotDownloader -app "1963720" -osarch 64 -dir . -validate
sudo chmod +x CoreKeeperServer

mkdir -p ~/.steam/sdk64/
ln -s ~/dedicated/linux64/steamclient.so ~/.steam/sdk64/steamclient.so

export ARCHITECTURE=arm64
export BOX64_DYNAREC_BIGBLOCK=0
export BOX64_DYNAREC_SAFEFLAGS=2
export BOX64_DYNAREC_STRONGMEM=3
export BOX64_DYNAREC_FASTROUND=0
export BOX64_DYNAREC_FASTNAN=0
export BOX64_DYNAREC_X87DOUBLE=1
export BOX64_DYNAREC_BLEEDING_EDGE=0
export BOX86_DYNAREC_BIGBLOCK=0
export BOX86_DYNAREC_SAFEFLAGS=2
export BOX86_DYNAREC_STRONGMEM=3
export BOX86_DYNAREC_FASTROUND=0
export BOX86_DYNAREC_FASTNAN=0
export BOX86_DYNAREC_X87DOUBLE=1
export BOX86_DYNAREC_BLEEDING_EDGE=0
export MESA_GL_VERSION_OVERRIDE=3.2
export BOX64_DYNAREC_STRONGMEM=1
export PAN_MESA_DEBUG=gl3
export TERM=xterm

sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

sudo apt-get install -y --no-install-recommends --no-install-suggests xvfb mesa-utils libx32gcc-s1-amd64-cross lib32gcc-s1-amd64-cross build-essential libxi6 x11-utils tini unzip libdbus-1-3 libxcursor1 libxss1 libpulse-dev libmonosgen-2.0 libmonosgen-2.0-1 libwayland-cursor0 libxkbcommon0

sudo apt-get install -y --no-install-recommends --no-install-suggests libxkbcommon0

Xvfb :99 -screen 0 1x1x24 -nolisten tcp &
export DISPLAY=:99
xvfbpid=$!

DISPLAY=:99 BOX64_LD_LIBRARY_PATH="BOX64_LD_LIBRARY_PATH:./linux64/" box64 ./CoreKeeperServer -batchmode -logfile "CoreKeeperServerLog2.txt"
DISPLAY=:99 LD_LIBRARY_PATH="$LD_LIBRARY_PATH:~/Steamworks SDK Redist/" box64 ./CoreKeeperServer -batchmode -logfile "CoreKeeperServerLog2.txt"

sudo apt update; sudo apt install software-properties-common; sudo apt-add-repository non-free; sudo dpkg --add-architecture i386; sudo apt update
sudo apt install steamcmd
```





# Things which may are interesting 
## steamCMD requirements 
steamCMD may needs at least 6GB of memory. This may could cause problems. Setting up a swap space within the container does not work. 
https://github.com/ptitSeb/box64?tab=readme-ov-file#notes-about-steam
> Note that Steam is a hybrid 32-bit / 64-bit. You NEED box86 to run Steam, as the client app is a 32-bit binary. It also uses a 64-bit local server binaries, and that steamwebhelper process is now mandatory, even on the "small mode". And that process will eat lots of memory. So machine with less the 6Gb of RAM will need a swapfile to use Steam.
Could be a problem on my 4GB RAM test system. 
https://linuxize.com/post/create-a-linux-swap-file/





# Sources 
Collection of all currently open tabs (unsorted an currently without further comments, may contains dulpicates)

* https://packages.debian.org/bookworm/libmonosgen-2.0-1
* https://developer.valvesoftware.com/wiki/SteamCMD
* https://steamcommunity.com/sharedfiles/filedetails/?id=2701668169
* https://github.com/sonroyaalmerol/steamcmd-arm64?tab=readme-ov-file
* https://github.com/ptitSeb/box64
* https://github.com/ptitSeb/box86-compatibility-list/issues/267
* https://github.com/JustaPenguin/assetto-server-manager/issues/11
* https://github.com/thijsvanloef/palworld-server-docker/blob/main/Dockerfile19
* https://github.com/thijsvanloef/palworld-server-docker/issues/10
* https://github.com/thijsvanloef/palworld-server-docker/blob/598679ab26f66b0028dd2e29e8213463df5f50e0/scripts/helper_install.sh
* https://github.com/JustaPenguin/assetto-server-manager/issues/1119
* https://github.com/chunsun21/palworld-dedicated-server-arm64
* https://github.com/yumusb/palworld-server-docker-arm
* https://github.com/nitrog0d/palworld-arm64/blob/master/Dockerfile
* https://github.com/TeriyakiGod/steamcmd-docker-arm64/blob/main/Dockerfile
* https://hub.docker.com/r/teriyakigod/steamcmd
* https://github.com/alex4108/palworld-server-docker/blob/main/scripts/init.sh
* https://github.com/haoyume/ssr/blob/master/docs/game-servers/install-steamcmd-for-a-steam-game-server.md#add-an-error-fix
* https://github.com/dgibbs64/SteamCMD-Commands-List/blob/main/steamcmd_commands.txt
* https://github.com/sonroyaalmerol/steamcmd-arm64
* https://hub.docker.com/r/sonroyaalmerol/steamcmd-arm64
* https://github.com/ptitSeb/box64/issues/1782
* https://github.com/ptitSeb/box64
* https://stackoverflow.com/questions/36273665/what-does-set-x-do
* https://stackoverflow.com/questions/13428910/how-to-set-the-environment-variable-ld-library-path-in-linux
* https://unix.stackexchange.com/questions/171262/ld-library-path-always-blank-after-sudo
* https://github.com/SteamRE/DepotDownloader?tab=readme-ov-file
* https://github.com/sonroyaalmerol/steamcmd-arm64?tab=readme-ov-file#what-makes-this-compatible-with-arm64
* https://magazine.odroid.com/article/playing-modern-fna-games-on-the-odroid-platform/
* https://github.com/Botspot/pi-apps/commit/570d212c1eab06721eb8f1a18584b38c07278b88#diff-9dacdd03ffbd2756a2e27273b45e074f8695ae87b835a18d5e6cf00297463d0dR46
* https://github.com/mono/linux-packaging-mono/blob/main/debian/libmonosgen-2.0-1.symbols.amd64
* https://stackoverflow.com/questions/70437760/issue-with-dpkg-when-trying-fix-broken-with-apt
* https://askubuntu.com/questions/124845/eerror-pkgproblemresolverresolve-generated-breaks-this-may-be-caused-by-hel
* https://askubuntu.com/questions/96/is-there-a-way-to-reset-all-packages-sources-and-start-from-scratch
* https://askubuntu.com/questions/428772/how-to-install-specific-version-of-some-package
* https://box86.org/2021/05/arm-gaming/
* https://github.com/ryanfortner/box86-debs
* https://github.com/ryanfortner/box64-debs
* https://github.com/ptitSeb/box64/issues/1782
* https://github.com/ValveSoftware/steam-for-linux/issues/1981
* https://steamcommunity.com/app/221410/discussions/0/882966056703960725/
* https://steamcommunity.com/discussions/forum/1/617329150706870073/?l=german
* https://stackoverflow.com/questions/67458621/how-to-run-amd64-docker-image-on-arm64-host-platform
* https://community.teklab.de/thread/5952-fatal-error-failed-to-load-libsteam-so/
* https://hub.docker.com/r/sonroyaalmerol/steamcmd-arm64
* https://github.com/ValveSoftware/steam-for-linux
* https://www.reddit.com/r/Palworld/comments/19bujr7/running_dedicated_server_with_steamcmd_on_arm/
* https://www.linuxforen.de/forums/showthread.php?68679-apt-get-install-glibc
* https://stackoverflow.com/questions/12697081/what-is-the-gmon-start-symbol
* https://wiki.fex-emu.com/index.php/Development:Setting_up_RootFS
* https://github.com/sonroyaalmerol/steamcmd-arm64
* https://github.com/xalimar/core-keeper-dedicated/blob/main/buster/Dockerfile
* https://steamcommunity.com/app/427520/discussions/5/2961670721756012757/
* https://github.com/ptitSeb/box64/issues/1478
* https://github.com/yumusb/palworld-server-docker-arm/blob/main/scripts/init.sh
* https://github.com/thijsvanloef/palworld-server-docker/blob/main/Dockerfile
* https://github.com/ptitSeb/box64/issues/1182
* https://github.com/ptitSeb/box64/issues/1182#issuecomment-2158845248
* https://gist.github.com/husjon/c5225997eb9798d38db9f2fca98891ef

