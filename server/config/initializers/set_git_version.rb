# Set app version from Git
# git describe --always
BLUSTEROMATIC_VERSION=`git describe --always`
BLUSTEROMATIC_VERSION.chomp!
BLUSTEROMATIC_VERSION="unknown rev" if BLUSTEROMATIC_VERSION.empty?
