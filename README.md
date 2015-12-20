# SickRage_QPKG
SickRage Server qpkg for QNAP

Steps required to build the package on a QNAP TVS:

    git clone https://github.com/eXodus1440/SickRage_QPKG.git SickRage
    cd SickRage/shared

    git clone https://github.com/SickRage/SickRage.git 
    mv SickRage/* SickRage/.* .
    rm -rf SickRage

    cd ..
    qbuild --exclude solaris --exclude *.cmd
