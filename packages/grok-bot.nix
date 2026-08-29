{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, alsa-lib
, at-spi2-core
, cairo
, cups
, dbus
, expat
, gdk-pixbuf
, glib
, gtk3
, libdrm
, libgbm
, libnotify
, libsecret
, libuuid
, libxkbcommon
, mesa
, nspr
, nss
, pango
, systemdLibs
, xdg-utils
, libX11
, libXScrnSaver
, libXtst
, libXcomposite
, libXdamage
, libXext
, libXfixes
, libXrandr
, libxcb
}:

stdenv.mkDerivation rec {
  pname = "grok-bot";
  version = "0.24.0";

  src = fetchurl {
    url = "https://downloads.cursor.com/grokbot/stable/302d75da596fc8d11ee0446a19b31c33c6676c2c/linux/x64/Grok_Bot_${version}.deb";
    hash = "sha256-X9CR1j+kEHF3N3l64LFJZ+TxVnyuIB0QyDRDDkgH8y0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libnotify
    libsecret
    libuuid
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemdLibs
    xdg-utils
    libX11
    libXScrnSaver
    libXtst
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt" "$out/bin" "$out/share/applications" "$out/share/icons/hicolor" "$out/share/licenses/${pname}"
    cp -a "opt/Grok Bot" "$out/opt/"
    cp -a usr/share/icons/hicolor/* "$out/share/icons/hicolor/"
    cp usr/share/applications/grok-bot.desktop "$out/share/applications/"
    substituteInPlace "$out/share/applications/grok-bot.desktop" \
      --replace-fail 'Exec="/opt/Grok Bot/grok-bot" %U' "Exec=$out/bin/grok-bot %U"

    makeWrapper "$out/opt/Grok Bot/grok-bot" "$out/bin/grok-bot" \
      --add-flags "--no-sandbox"

    cp "$out/opt/Grok Bot/LICENSE.electron.txt" "$out/share/licenses/${pname}/"

    runHook postInstall
  '';

  meta = {
    description = "Grok Bot desktop agent";
    homepage = "https://x.ai/bot";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "grok-bot";
  };
}
