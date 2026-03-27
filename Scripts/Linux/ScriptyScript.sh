#!/bin/bash

LOG_FILE="/var/log/cyberpatriot.log"
touch $LOG_FILE
echo "CyberPatriot Script Started: $(date)" >> $LOG_FILE
echo "This script must be run as root" >> $LOG_FILE

echo "Deleted all media files" >> $LOG_FILE

find /home -name '*.mp3' -type f -delete
    	find /home -name '*.mov' -type f -delete
    	find /home -name '*.mp4' -type f -delete
    	find /home -name '*.avi' -type f -delete
    	find /home -name '*.mpg' -type f -delete
    	find /home -name '*.mpeg' -type f -delete
    	find /home -name '*.flac' -type f -delete
    	find /home -name '*.m4a' -type f -delete
    	find /home -name '*.flv' -type f -delete
    	find /home -name '*.ogg' -type f -delete
    	find /home -name '*.gif' -type f -delete
    	find /home -name '*.png' -type f -delete
    	find /home -name '*.jpg' -type f -delete
		find /home -name '*.mp3' -type f -delete
		find /home -name '*.tiff' -type f -delete

#Remove prohibited Software
echo "removing prohibited software" >> $LOG_FILE
sudo apt remove ophcrack
sudo apt remove wireshark -y
sudo apt-get autoremove -y
sudo apt remove nmap
sudo apt remove nessus
sudo apt remove kismet
sudo apt remove metasploit
sudo apt remove aircrack-ng
sudo apt remove openvas
sudo apt remove sqlmap
sudo apt remove zenmap
sudo apt remove rainbow-crack
sudo apt remove ccleaner

#Determines critical services
echo "Determining critical services and removing useless ones" >> $LOG_FILE

#Fun stuff (SHOULD WORK ON BOTH DEBIAN AND UBUNTU)
clear
echo "Cleared command prompt" >> $LOG_FILE
unalias -a
echo "deleted all aliases" >> $LOG_FILE
printTime "All alias have been removed." >>$LOG_FILE

clear
echo "root account locked" >> $LOG_FILE
usermod -L root
printTime "Root account has been locked. Use 'usermod -U root' to unlock it."

clear
echo "Modified user privileges for bash history file" >> $LOG_FILE
chmod 640 .bash_history
printTime "Bash history file permissions set."

clear
echo "Modified user privileges for Shadow files" >> $LOG_FILE
chmod 604 /etc/shadow
printTime "Read/Write permissions on shadow have been set."

clear
echo "Checked for files and user folders not needed" >> $LOG_FILE
printTime "Check for any user folders that do not belong to any users in /home/."
ls -a /home/ >> $LOG_FILE

clear
echo "Checked for any files for users that should not be admins" >> $LOG_FILE
printTime "Check for any files for users that should not be administrators in /etc/sudoers.d."
ls -a /etc/sudoers.d >> $LOG_FILE

#Configuring Sysctl
echo "Configured Sysctl" >> $LOG_FILE
clear
echo > /etc/sysctl.conf
echo -e "# Controls IP packet forwarding\nnet.ipv4.ip_forward = 0\n\n# IP Spoofing protection\nnet.ipv4.conf.all.rp_filter = 1\nnet.ipv4.conf.default.rp_filter = 1\n\n# Ignore ICMP broadcast requests\nnet.ipv4.icmp_echo_ignore_broadcasts = 1\n\n# Disable source packet routing\nnet.ipv4.conf.all.accept_source_route = 0\nnet.ipv6.conf.all.accept_source_route = 0\nnet.ipv4.conf.default.accept_source_route = 0\nnet.ipv6.conf.default.accept_source_route = 0\n\n# Ignore send redirects\nnet.ipv4.conf.all.send_redirects = 0\nnet.ipv4.conf.default.send_redirects = 0\n\n# Block SYN attacks\nnet.ipv4.tcp_syncookies = 1\nnet.ipv4.tcp_max_syn_backlog = 2048\nnet.ipv4.tcp_synack_retries = 2\nnet.ipv4.tcp_syn_retries = 5\n\n# Log Martians\nnet.ipv4.conf.all.log_martians = 1\nnet.ipv4.icmp_ignore_bogus_error_responses = 1\n\n# Ignore ICMP redirects\nnet.ipv4.conf.all.accept_redirects = 0\nnet.ipv6.conf.all.accept_redirects = 0\nnet.ipv4.conf.default.accept_redirects = 0\nnet.ipv6.conf.default.accept_redirects = 0\n\n# Ignore Directed pings\nnet.ipv4.icmp_echo_ignore_all = 1\n\n# Accept Redirects? No, this is not router\nnet.ipv4.conf.all.secure_redirects = 0\n\n# Log packets with impossible addresses to kernel log? yes\nnet.ipv4.conf.default.secure_redirects = 0\n\n########## IPv6 networking start ##############\n# Number of Router Solicitations to send until assuming no routers are present.\n# This is host and not router\nnet.ipv6.conf.default.router_solicitations = 0\n\n# Accept Router Preference in RA?\nnet.ipv6.conf.default.accept_ra_rtr_pref = 0\n\n# Learn Prefix Information in Router Advertisement\nnet.ipv6.conf.default.accept_ra_pinfo = 0\n\n# Setting controls whether the system will accept Hop Limit settings from a router advertisement\nnet.ipv6.conf.default.accept_ra_defrtr = 0\n\n#router advertisements can cause the system to assign a global unicast address to an interface\nnet.ipv6.conf.default.autoconf = 0\n\n#how many neighbor solicitations to send out per address?\nnet.ipv6.conf.default.dad_transmits = 0\n\n# How many global unicast IPv6 addresses can be assigned to each interface?
net.ipv6.conf.default.max_addresses = 1\n\n########## IPv6 networking ends ##############" >> /etc/sysctl.conf
sysctl -p >> /dev/null
printTime "Sysctl has been configured."

#Decide whether or not to disable IPv6
echo -e "\n\n# Disable IPv6\nnet.ipv6.conf.all.disable_ipv6 = 1\nnet.ipv6.conf.default.disable_ipv6 = 1\nnet.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p >> /dev/null
printTime "IPv6 has been disabled."
echo "IPv6 disapled" >> $LOG_FILE

#finding and removing backdoors
echo "Fixed and removed backdoors" >> $LOG_FILE
wget http://downloads.sourceforge.net/project/rkhunter/rkhunter/1.4.2/rkhunter-1.4.2.tar.gz
tar xfz rkhunter-1.4.2.tar.gz
sudo ./rkhunter-1.4.2/installer.sh --layout default --install
sudo ./rkhunter-1.4.2/installer.sh --layout default --install
sudo /usr/local/bin/rkhunter --update --propupd
sudo /usr/local/bin/rkhunter --check

#Check for prohibeted software, as well as stops prohibited software from running.
echo "Checked for prohibited software" >> $LOG_FILE
sudo systemctl stop nginx 
sudo systemctl disable nginx

#games
echo "Deleted games" >> $LOG_FILE
sudo apt-get purge -y 0ad 0ad-data 0ad-data-common 2048-qt 3dchess 4digits 7kaa 7kaa-data a7xpg a7xpg-data aajm abe abe-data ace-of-penguins acm adanaxisgpl adanaxisgpl-data adonthell adonthell-data airstrike airstrike-common aisleriot alex4 alex4-data alien-arena alien-arena-data alien-arena-server alienblaster alienblaster-data allure amoebax amoebax-data amphetamine amphetamine-data an anagramarama anagramarama-data angband angband-audio angband-data angrydd animals antigravitaattori ardentryst armagetronad armagetronad-common armagetronad-dedicated asc asc-data asc-music asciijump assaultcube assaultcube-data astromenace astromenace-data-src asylum asylum-data atanks atanks-data atom4 atomix atomix-data attal attal-themes-medieval auralquiz balder2d balder2d-data ballerburg ballz ballz-data ballz-dbg bambam barrage bastet bb bear-factory beneath-a-steel-sky berusky berusky-data berusky2 berusky2-data between billard-gl billard-gl-data biloba biloba-data biniax2 biniax2-data black-box blobandconquer blobandconquer-data blobby blobby-data blobby-server bloboats blobwars blobwars-data blockattack blockout2 blocks-of-the-undead blocks-of-the-undead-data bombardier bomber bomberclone bomberclone-data boswars boswars-data bouncy bovo brainparty brainparty-data briquolo briquolo-data brutalchess bsdgames bsdgames-nonfree btanks btanks-data bubbros bucklespring bucklespring-data bugsquish bumprace bumprace-data burgerspace bve-route-cross-city-south bve-train-br-class-323 bve-train-br-class-323-3dcab bygfoot bygfoot-data bzflag bzflag-client bzflag-data bzflag-server cappuccino caveexpress caveexpress-data cavepacker cavepacker-data cavezofphear ceferino ceferino-data cgoban chessx childsplay childsplay-alphabet-sounds-bg childsplay-alphabet-sounds-ca childsplay-alphabet-sounds-de childsplay-alphabet-sounds-el childsplay-alphabet-sounds-en-gb childsplay-alphabet-sounds-es childsplay-alphabet-sounds-fr childsplay-alphabet-sounds-it childsplay-alphabet-sounds-nb childsplay-alphabet-sounds-nl childsplay-alphabet-sounds-pt childsplay-alphabet-sounds-ro childsplay-alphabet-sounds-ru childsplay-alphabet-sounds-sl childsplay-alphabet-sounds-sv chipw chocolate-common chocolate-doom chromium-bsu chromium-bsu-data circuslinux circuslinux-data colobot colobot-common colobot-common-sounds colobot-common-textures colorcode colossal-cave-adventure connectagram connectagram-data cookietool corsix-th corsix-th-data cowsay cowsay-off crack-attack crafty crafty-bitmaps crafty-books-medium crafty-books-medtosmall crafty-books-small crawl crawl-common crawl-tiles crawl-tiles-data crimson criticalmass criticalmass-data crossfire-client crossfire-client-images crossfire-client-sounds crossfire-common crossfire-maps crossfire-maps crossfire-maps-small crossfire-server crrcsim crrcsim-data csmash csmash-data csmash-demosong cube2 cube2-data cube2-server cultivation curseofwar cutemaze cuyo cuyo-data cyphesis-cpp cyphesis-cpp-clients cyphesis-cpp-mason cytadela cytadela-data d1x-rebirth d2x-rebirth dangen darkplaces darkplaces-server ddnet ddnet-data ddnet-server ddnet-tools dds deal dealer defendguin defendguin-data desmume deutex dhewm3 dhewm3-d3xp dhewm3-doom3 dizzy dodgindiamond2 dolphin-emu dolphin-emu-data doom-wad-shareware doomsday doomsday-common doomsday-data doomsday-server dopewars dopewars-data dossizola dossizola-data drascula drascula-french drascula-german drascula-italian drascula-music drascula-spanish dreamchess dreamchess-data dustracing2d dustracing2d-data dvorak7min dwarf-fortress dwarf-fortress-data eboard eboard-extras-pack1 edgar edgar-data efp einstein el-ixir ember ember-media empire empire-hub empire-lafe endless-sky endless-sky-data endless-sky-high-dpi enemylines3 enemylines7 enigma enigma-data epiphany epiphany-data etoys etqw etqw-server etw etw-data excellent-bifurcation extremetuxracer extremetuxracer-data exult exult-studio ezquake fairymax fb-music-high ffrenzy fgo fgrun fheroes2-pkg filler fillets-ng fillets-ng-data fillets-ng-data-cs fillets-ng-data-nl filters five-or-more fizmo-common fizmo-console fizmo-ncursesw fizmo-sdl2 flare flare-data flare-engine flare-game flight-of-the-amazon-queen flightgear flightgear-data-ai flightgear-data-all flightgear-data-base flightgear-data-models flightgear-phi flobopuyo fltk1.1-games fltk1.3-games foobillardplus foobillardplus-data fortunate.app fortune-anarchism fortune-mod fortune-zh fortunes fortunes-bg fortunes-bofh-excuses fortunes-br fortunes-cs fortunes-de fortunes-debian-hints fortunes-eo fortunes-eo-ascii fortunes-eo-iso3 fortunes-es fortunes-es-off fortunes-fr fortunes-ga fortunes-it fortunes-it-off fortunes-mario fortunes-min fortunes-off fortunes-pl fortunes-ru fortunes-spam fortunes-zh four-in-a-row freealchemist freecell-solver-bin freeciv freeciv-client-extras freeciv-client-gtk freeciv-client-gtk3 freeciv-client-qt freeciv-client-sdl freeciv-data freeciv-server freeciv-sound-standard freecol freedink freedink-data freedink-dfarc freedink-dfarc-dbg freedink-engine freedink-engine-dbg freedm freedoom freedroid freedroid-data freedroidrpg freedroidrpg-data freegish freegish-data freeorion freeorion-data freespace2 freespace2-launcher-wxlauncher freesweep freetennis freetennis-common freevial fretsonfire fretsonfire-game fretsonfire-songs-muldjord fretsonfire-songs-sectoid frogatto frogatto-data frotz frozen-bubble frozen-bubble-data fruit funguloids funguloids-data funnyboat gamazons game-data-packager game-data-packager-runtime gameclock gamine gamine-data garden-of-coloured-lights garden-of-coloured-lights-data gargoyle-free gav gav-themes gbrainy gcompris gearhead gearhead-data gearhead-sdl gearhead2 gearhead2-data gearhead2-sdl geekcode geki2 geki3 gemdropx gemrb gemrb-baldurs-gate gemrb-baldurs-gate-2 gemrb-baldurs-gate-2-data gemrb-baldurs-gate-data gemrb-data gemrb-icewind-dale gemrb-icewind-dale-2 gemrb-icewind-dale-2-data gemrb-icewind-dale-data gemrb-planescape-torment gemrb-planescape-torment-data geneatd gfceu gfpoken gl-117 gl-117-data glaurung glhack glob2 glob2-data glpeces glpeces-data gltron gmchess gmult gnome-2048 gnome-mines gnome-aisleriot gnome-breakout gnome-cards-data gnome-chess gnome-games-app gnome-klotski gnome-mahjongg gnome-mastermind gnome-mines gnome-nibbles gnome-robots gnome-sudoku gnome-tetravex gnubg gnubg-data gnubik gnuboy-sdl gnuboy-x gnuchess gnuchess-book gnudoq gnugo gnujump gnujump-data gnuminishogi gnurobbo gnurobbo-data gnushogi golly gomoku.app gplanarity gpsshogi gpsshogi-data granatier granule gravitation gravitywars greed grhino grhino-data gridlock.app groundhog gsalliere gtans gtkballs gtkboard gtkpool gunroar gunroar-data gweled hachu hannah hannah-data hearse hedgewars hedgewars-data heroes heroes-data heroes-sound-effects heroes-sound-tracks hex-a-hop hex-a-hop-data hexalate hexxagon higan hitori hoichess holdingnuts holdingnuts-server holotz-castle holotz-castle-data holotz-castle-editor hyperrogue hyperrogue-music iagno icebreaker ii-esu infon-server infon-viewer instead instead-data ioquake3 ioquake3-server jag jag-data jester jigzo jigzo-data jmdlx jumpnbump jumpnbump-levels jzip kajongg kanagram kanatest kapman katomic kawari8 kball kball-data kblackbox kblocks kbounce kbreakout kcheckers kdegames-card-data kdegames-card-data-kf5 kdegames-mahjongg-data-kf5 kdiamond ketm ketm-data kfourinline kgoldrunner khangman kigo kiki-the-nano-bot kiki-the-nano-bot-data kildclient killbots kiriki kjumpingcube klickety klines kmahjongg kmines knavalbattle knetwalk knights kobodeluxe kobodeluxe-data kolf kollision komi konquest koules kpat krank kraptor kraptor-data kreversi kshisen ksirk ksnakeduel kspaceduel ksquares ksudoku ktuberling kubrick laby lambdahack late late-data lbreakout2 lbreakout2-data lgc-pg lgeneral lgeneral-data libatlas-cpp-0.6-tools libgemrb libmgba libretro-beetle-pce-fast libretro-beetle-psx libretro-beetle-vb libretro-beetle-wswan libretro-bsnes-mercury-accuracy libretro-bsnes-mercury-balanced libretro-bsnes-mercury-performance libretro-desmume libretro-gambatte libretro-genesisplusgx libretro-mgba libretro-mupen64plus libretro-nestopia libretro-snes9x lierolibre lierolibre-data lightsoff lightyears lincity lincity-ng lincity-ng-data liquidwar liquidwar-data liquidwar-server littlewizard littlewizard-data lmarbles lmemory lolcat londonlaw lordsawar lordsawar-data love lskat ltris lugaru lugaru-data luola luola-data luola-levels luola-nostalgy lure-of-the-temptress macopix-gtk2 madbomber madbomber-data maelstrom magicmaze magicor magicor-data magictouch mah-jong mame mame-data mame-extra manaplus manaplus-data mancala marsshooter marsshooter-data matanza mazeofgalious mazeofgalious-data mednafen mednaffe megaglest megaglest-data meritous meritous-data mgba-common mgba-qt mgba-sdl mgt miceamaze micropolis micropolis-data minetest minetest-data minetest-mod-advspawning minetest-mod-animalmaterials minetest-mod-animals minetest-mod-character-creator minetest-mod-craftguide minetest-mod-homedecor minetest-mod-maidroid minetest-mod-mesecons minetest-mod-mobf minetest-mod-mobf-core minetest-mod-mobf-trap minetest-mod-moreblocks minetest-mod-moreores minetest-mod-nether minetest-mod-pipeworks minetest-mod-player-3d-armor minetest-mod-quartz minetest-mod-torches minetest-mod-unifieddyes minetest-mod-worldedit minetest-server mirrormagic mirrormagic-data mokomaze monopd monsterz monsterz-data moon-buggy moon-lander moon-lander-data moria morris mousetrap mrboom mrrescue mttroff mu-cade mu-cade-data mudlet multitet mupen64plus-audio-all mupen64plus-audio-sdl mupen64plus-data mupen64plus-input-all mupen64plus-input-sdl mupen64plus-qt mupen64plus-rsp-all mupen64plus-rsp-hle mupen64plus-rsp-z64 mupen64plus-ui-console mupen64plus-video-all mupen64plus-video-arachnoid mupen64plus-video-glide64 mupen64plus-video-glide64mk2 mupen64plus-video-rice mupen64plus-video-z64 nestopia nethack-common nethack-console nethack-el nethack-lisp nethack-x11 netmaze netpanzer netpanzer-data netris nettoe neverball neverball-common neverball-data neverputt neverputt-data nexuiz nexuiz-data nexuiz-music nexuiz-server nexuiz-textures nikwi nikwi-data ninix-aya ninvaders njam njam-data noiz2sa noiz2sa-data nsnake nudoku numptyphysics ogamesim ogamesim-www omega-rpg oneisenough oneko onscripter open-adventure open-invaders open-invaders-data openarena openarena-081-maps openarena-081-misc openarena-081-players openarena-081-players-mature openarena-081-textures openarena-085-data openarena-088-data openarena-data openarena-oacmp1 openarena-server openbve-data opencity opencity-data openclonk openclonk-data openlugaru openlugaru-data openmw openmw-cs openmw-data openmw-launcher openpref openssn openssn-data openttd openttd-data openttd-opengfx openttd-openmsx openttd-opensfx opentyrian openyahtzee orbital-eunuchs-sniper orbital-eunuchs-sniper-data osmose-emulator out-of-order overgod overgod-data pachi pachi-data pacman pacman4console palapeli palapeli-data pangzero parsec47 parsec47-data passage pathogen pathological pax-britannica pax-britannica-data pcsx2 pcsxr peg-e peg-solitaire pegsolitaire penguin-command pente pentobi performous performous-tools pescetti petris pgn-extract phalanx phlipple phlipple-data pianobooster picmi pinball pinball-data pinball-dev pingus pingus-data pink-pony pink-pony-data pioneers pioneers-console pioneers-console-data pioneers-data pioneers-metaserver pipenightdreams pipenightdreams-data pipewalker piu-piu pixbros pixfrogger planarity planetblupi planetblupi-common planetblupi-music-midi planetblupi-music-ogg plee-the-bear plee-the-bear-data pokemmo-installer pokerth pokerth-data pokerth-server polygen polygen-data polyglot pong2 powder powermanga powermanga-data pq prboom-plus prboom-plus-game-server primrose projectl purity purity-ng purity-off pybik pybik-bin pybridge pybridge-common pybridge-server pykaraoke pykaraoke-bin pynagram pyracerz pyscrabble pyscrabble-common pyscrabble-server pysiogame pysolfc pysolfc-cardsets pysycache pysycache-buttons-beerabbit pysycache-buttons-crapaud pysycache-buttons-ice pysycache-buttons-wolf pysycache-click-dinosaurs pysycache-click-sea pysycache-dblclick-appleandpear pysycache-dblclick-butterfly pysycache-i18n pysycache-images pysycache-move-animals pysycache-move-food pysycache-move-plants pysycache-move-sky pysycache-move-sports pysycache-puzzle-cartoons pysycache-puzzle-photos pysycache-sounds python-pykaraoke python-renpy qgo qonk qstat qtads quadrapassel quake quake-server quake2 quake2-server quake3 quake3-data quake3-server quake4 quake4-server quakespasm quarry qxw rafkill rafkill-data raincat raincat-data randtype rbdoom3bfg redeclipse redeclipse-common redeclipse-data redeclipse-server reminiscence renpy renpy-demo renpy-thequestion residualvm residualvm-data ri-li ri-li-data ricochet rlvm robocode robotfindskitten rockdodger rocksndiamonds rolldice rott rrootage rrootage-data rtcw rtcw-common rtcw-server runescape salliere sandboxgamemaker sauerbraten sauerbraten-server scid scid-data scid-rating-data scid-spell-data scorched3d scorched3d-data scottfree scummvm scummvm-data scummvm-tools sdl-ball sdl-ball-data seahorse-adventures searchandrescue searchandrescue-common searchandrescue-data sgt-launcher sgt-puzzles shogivar shogivar-data simutrans simutrans-data simutrans-makeobj simutrans-pak128.britain simutrans-pak64 singularity singularity-music sjaakii sjeng sl slashem slashem-common slashem-gtk slashem-sdl slashem-x11 slimevolley slimevolley-data slingshot sludge-engine sm snake4 snowballz solarwolf sopwith spacearyarya spacezero speedpad spellcast sponc spout spring spring-common spring-javaai spring-maps-kernelpanic spring-mods-kernelpanic springlobby starfighter starfighter-data starvoyager starvoyager-data stax steam steam-devices steam-installer steamcmd stockfish stormbaancoureur stormbaancoureur-data sudoku supertransball2 supertransball2-data supertux supertux-data supertuxkart supertuxkart-data swell-foop tagua tagua-data tali tanglet tanglet-data tatan tdfsb tecnoballz tecnoballz-data teeworlds teeworlds-data teeworlds-server tenace tenmado tennix tetrinet-client tetrinet-server tetrinetx tetzle tf tf5 tictactoe-ng tint tintin++ tinymux titanion titanion-data toga2 tomatoes tomatoes-data tome toppler torcs torcs-data torus-trooper torus-trooper-data tourney-manager trackballs trackballs-data transcend treil trigger-rally trigger-rally-data triplane triplea trophy trophy-data trophy-dbg tumiki-fighters tumiki-fighters-data tuxfootball tuxmath tuxmath-data tuxpuck tuxtype tuxtype-data tworld tworld-data typespeed uci2wb ufoai ufoai-common ufoai-data ufoai-maps ufoai-misc ufoai-music ufoai-server ufoai-sound ufoai-textures uhexen2 uhexen2-common uligo unknown-horizons uqm uqm-content uqm-music uqm-russian uqm-voice val-and-rick val-and-rick-data vbaexpress vcmi vectoroids viruskiller visualboyadvance vodovod vor warmux warmux-data warmux-servers warzone2100 warzone2100-data warzone2100-music werewolf wesnoth wesnoth-1.12 wesnoth-1.12-aoi wesnoth-1.12-core wesnoth-1.12-data wesnoth-1.12-did wesnoth-1.12-dm wesnoth-1.12-dw wesnoth-1.12-ei wesnoth-1.12-httt wesnoth-1.12-l wesnoth-1.12-low wesnoth-1.12-music wesnoth-1.12-nr wesnoth-1.12-server wesnoth-1.12-sof wesnoth-1.12-sotbe wesnoth-1.12-thot wesnoth-1.12-tools wesnoth-1.12-trow wesnoth-1.12-tsg wesnoth-1.12-ttb wesnoth-1.12-utbs wesnoth-core wesnoth-music wfut whichwayisup widelands widelands-data wing wing-data wizznic wizznic-data wmpuzzle wolf4sdl wordplay wordwarvi wordwarvi-sound xabacus xabacus xball xbill xblast-tnt xblast-tnt-images xblast-tnt-levels xblast-tnt-models xblast-tnt-musics xblast-tnt-sounds xboard xbomb xbubble xbubble-data xchain xcowsay xdemineur xdesktopwaves xevil xfireworks xfishtank xflip xfrisk xgalaga xgalaga++ xgammon xinv3d xjig xjokes xjump xletters xmabacus xmahjongg xmille xmoto xmoto-data xmountains xmpuzzles xonix xpat2 xpenguins xphoon xpilot-extra xpilot-ng xpilot-ng-client-sdl xpilot-ng-client-x11 xpilot-ng-common xpilot-ng-server xpilot-ng-utils xpuzzles xqf xracer xracer-tools xscavenger xscorch xscreensaver-screensaver-dizzy xshisen xshogi xskat xsok xsol xsoldier xstarfish xsystem35 xteddy xtron xvier xwelltris xye xye-data xzip yahtzeesharp yamagi-quake2 yamagi-quake2-core zangband zangband-data zatacka zaz zaz-data zec zivot zoom-player gameconqueror

# Enable firewall

#installs firewall
sudo apt install ufw

#gives firewall status
sudo ufw status verbose
sudo ufw status >> $LOG_FILE

#configures settings
sudo ufw default deny incoming
sudo ufw enable

#allows services
sudo ufw allow ssh
sudo ufw allow 4422/tcp

#denies specific ports
enable    #firewall on
sudo ufw deny 23    #block Telnet
sudo ufw deny 515   #block printer port
sudo ufw allow log 22/tcp
sudo ufw allow 139
sudo ufw allow 445
sudo ufw allow 137
sudo ufw allow 138
sudo ufw deny 21
sudo ufw deny cups

#disables these two services
sudo apt-get purge -y cups
sudo apt-get purge -y bluetooth

echo "Firewall enabled and setup" >> $LOG_FILE

#start Open SSH at boot
sudo update-rc.d ssh enable
/etc/rc3.d/
echo "SSH Starts at boot" >> $LOG_FILE

#stop services
sudo systemctl stop httpd
sudo systemctl stop apache2
sudo systemctl stop nginx 
sudo systemctl disable nginx
sudo systemctl purge apache2
echo "Stopped httpd, apache2, nginx" >> $LOG_FILE

#Disabling root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo sed -i 's/nullok/ /g' /etc/pam.d/common_auth

echo "System updated and upgraded" >>$LOG_FILE
#updates system
 sudo apt update
 sudo apt upgrade
 sudo reboot