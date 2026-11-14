FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm archiso git base-devel sudo curl && \
    pacman -Scc --noconfirm

RUN useradd -m builder && \
    echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# VS Code (公式バイナリ) をローカルリポジトリ用にパッケージ化
RUN mkdir -p /tmp/vscode-pkg /customrepo && \
    cat << 'EOF' > /tmp/vscode-pkg/PKGBUILD
pkgname=visual-studio-code-bin
pkgver=latest
pkgrel=1
pkgdesc="Visual Studio Code (Official Binary)"
arch=('x86_64')
url="https://visualstudio.com"
license=('custom')
depends=('libxkbfile' 'gnupg' 'gtk3' 'libsecret' 'nss' 'gcc-libs' 'libnotify' 'libxss' 'glibc' 'lsof' 'shared-mime-info' 'xdg-utils' 'alsa-lib')
source=("vscode.tar.gz::https://visualstudio.comsha/download?build=stable&os=linux-x64")
sha256sums=('SKIP')

package() {
  install -d "$pkgdir/opt/visual-studio-code"
  cp -r "$srcdir/VSCode-linux-x64/"* "$pkgdir/opt/visual-studio-code/"
  install -d "$pkgdir/usr/bin"
  ln -s /opt/visual-studio-code/bin/code "$pkgdir/usr/bin/code"
  
  install -d "$pkgdir/usr/share/applications"
  cat << 'DESKTOP' > "$pkgdir/usr/share/applications/code.desktop"
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=/usr/bin/code %F
Icon=/opt/visual-studio-code/resources/app/resources/linux/code.png
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=TextEditor;Development;IDE;
MimeType=application/x-code-workspace;
DESKTOP
}
EOF

RUN chown -R builder:builder /tmp/vscode-pkg /customrepo && \
    su - builder -c "cd /tmp/vscode-pkg && makepkg -s --noconfirm && cp *.pkg.tar.* /customrepo/" && \
    repo-add /customrepo/customrepo.db.tar.gz /customrepo/*.pkg.tar.* && \
    rm -rf /tmp/vscode-pkg

WORKDIR /build
