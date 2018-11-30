# SickRage_QPKG
SickRage Server qpkg for QNAP

Steps required to build the package on a QNAP TVS:

    git clone https://github.com/eXodus1440/SickRage_QPKG.git SickChill
    cd SickChill/shared

    git clone https://github.com/SickChill/SickChill.git 
    mv SickChill/* SickChill/.* .
    rm -rf SickChill

    cd ..
    qbuild --exclude solaris --exclude *.cmd
