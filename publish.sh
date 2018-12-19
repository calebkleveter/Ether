if brew gdate 2>/dev/null; then
    echo "🍺 Updating Homebrew Formulae"
    brew upgrade
else
    echo "Make sure you have the latest version of LibreSSL installed"

    while true; do
        read -p "Continue? [Y/n]" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

echo "📦  Updating Swift packages..."
swift package update
swift package resolve

echo "📦  Determining latest Git tag..."
TAG=$(git describe --abbrev=0 --tags);

echo "📦  Updating compiled version to $TAG..."
cat ./Sources/Executable/main.swift | \
    awk -v tag="$TAG" '/let version = "master"/ { printf "let version = \"%s\"\n", tag; next } 1' > .tmp && \
    mv .tmp Sources/Executable/main.swift;

echo "📦  Building..."
swift build -c release -Xswiftc -static-stdlib

echo "📦  Creating package..."
EXEC_NAME="ether"
PACKAGE_NAME="ether-$TAG"
mkdir -p ./$PACKAGE_NAME

README="./$PACKAGE_NAME/README.txt"

echo "Manual Install Instructions for Ether v$TAG" > $README
echo "" >> $README
echo "- Move *.dylib files into /usr/local/lib" >> $README
echo "- Move executable $EXEC_NAME into /usr/local/bin" >> $README
echo "- Type '$EXEC_NAME --help' into terminal to verify installation" >> $README

cp .build/release/Executable ./$PACKAGE_NAME/$EXEC_NAME

tar -cvzf macOS-sierra.tar.gz ./$PACKAGE_NAME
HASH=$(shasum -a 256 macOS-sierra.tar.gz | cut -d " " -f 1)

echo "📦  Drag and drop $PWD/macOS-sierra.tar.gz into https://github.com/Ether-CLI/Ether/releases/edit/$TAG"

while true; do
    read -p "Have you finished uploading? [y/n]" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

cd ../
git clone git@github.com:Ether-CLI/homebrew-tap.git
cd homebrew-tap

cat > ether.rb <<- EOM
class Ether < Formula
  homepage "https://github.com/Ether-CLI/Ether"
  version "$TAG"
  url "https://github.com/calebkleveter/Ether/releases/download/#{version}/macOS-sierra.tar.gz"
  sha256 "$HASH"

  depends_on "libressl"

  def install
    bin.install "ether"
  end
end
EOM

git add .
git commit -S -m "Updated Ether version to $TAG"
git push origin master
cd ../
rm -rf homebrew-tap

cd Ether/
rm -rf macOS-sierra.tar.gz
rm -rf $PACKAGE_NAME
rm install
