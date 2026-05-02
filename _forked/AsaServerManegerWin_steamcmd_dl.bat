curl -O https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip
powershell Expand-Archive -Path steamcmd.zip steamcmd
cd steamcmd
steamcmd +quit
cd ..
