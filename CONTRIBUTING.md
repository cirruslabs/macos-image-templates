## GitHub Actions Self-hosted Runner イメージ更新の仕方

monoxer_iosでは仮想マシンを用いてVenturaのCI環境をホストしています。XcodeやOSが更新された際にはベースイメージを更新する必要があります。以下にベースイメージ更新の手順を述べます。

### リポジトリの更新

OSのバージョンが更新された際にはvanilla-ventura.pkr.hclを更新する必要があります。from_ipswが含まれる行のURLが更新の対象となります。この行にはApple公式のOSリカバリイメージのURLを指定します。 https://ipsw.me/ でMacの画像をクリックするとOSのバージョンの一覧が出て、そこから最新のSigned IPSWをダウンロードできるURLが取得できるので、それをfrom_ipswのURLに指定します。変更をしたらmonoxer-imagesブランチに対してプルリクエストを出します。

### ベースイメージの作成

ベースイメージは手元のMacで作成し、Artifact Registryにアップロードしてから、実際にランナーを動かすMac StudioやMac miniにダウンロードします。ここでは、以下の順番で2つのイメージを4段階の手順で作成します。

1. macOSのシステムのみがインストールされたバニライメージ (vanilla-ventura)
2. SIPを解除したバニライメージ (vanilla-ventura)
3. monoxer_iosのビルドに必要な周辺ツールを導入したモノグサイメージ (ventura-monoxer)
4. 必要なXcodeをインストールしたモノグサイメージ

ベースイメージの作成にはPackerとTartというソフトウェアが必要であり、両方ともHomebrewからインストールできます。インストールコマンドは以下の通りです。

```
brew install hashicorp/tap/packer cirruslabs/cli/tart
```

PackerとTartをインストールしたら、ベースイメージのビルドを行います。ターミナルを起動し、カレントディレクトリをクローンしたこのリポジトリのルートに設定し、次のコマンドを実行します。

```
packer init templates/ventura-vanilla.pkr.hcl
```

このコマンドにより、PackerにTartでイメージを構築するためのプラグインがインストールされます。次にバニライメージを構築するために以下のコマンドを実行します。

```
packer build templates/ventura-vanilla.pkr.hcl
```

このコマンドによりmacOSのリカバリイメージがダウンロードされ、初期セットアップが自動で実行されます。このコマンドを実行すると仮想マシンのディスプレイが開きますが、全て自動で操作されるので、仮想マシンのディスプレイに対していかなる操作も行わないでください。このステップは有線接続ありで、だいたい60分くらいかかります。音声が流れるので注意して下さい。
この手順が終わったら、次に示すコマンドを実行します。

```
packer build -var vm_name=ventura-vanilla templates/disable-sip.pkr.hcl
```

このコマンドにより、ventura-vanillaが変更され、macOSのセキュリティ機能であるSIPが解除されます。
この手順が終わったら、次に示すコマンドを実行します。

```
packer build templates/ventura-monoxer.pkr.hcl
```

次のコマンドを実行し、仮想マシンを起動します。

```
tart run ventura-monoxer
```

仮想マシンのウィンドウが表示されたら、Launchpadからターミナルを起動して次のコマンドを実行します。

```
XCODE_VERSION=14.2
xcodes install $XCODE_VERSION --experimental-unxip
```

Apple IDを聞かれるので自分のApple IDでログインします。正しくログインできればXcodeのダウンロードが始まります。
Xcodeのインストールが終わったら次のコマンドを実行します。

```
xcodes select $XCODE_VERSION
xcodebuild -runFirstLaunch
brew install swiftlint
```

完了したら仮想マシンをシャットダウンします。これでイメージは完成です。

### イメージのアップロード

イメージをアップロードするためにはArtifact Registryに書き込み権限があるアカウントでログインされたgcloudコマンドが必要です。次のコマンドを実行します。
長時間接続を維持しなければならないので、有線接続の上、電源に接続し、スリープしない設定にすることを推奨します。

```
MACOS_VERSION=13.2
TAG=$XCODE_VERSION-$MACOS_VERSION
gcloud auth print-access-token | tart login asia-northeast1-docker.pkg.dev --username oauth2accesstoken --password-stdin
tart push ventura-monoxer asia-northeast1-docker.pkg.dev/omega-fabric-148305/monoxer-ghactions/macos-ventura-monoxer:$TAG
```

### イメージのダウンロード

イメージのダウンロードはMac Studio上で次のコマンドを実行します。Artifact Registryの読み取り権限があるアカウントでログインされたgcloudコマンドが必要です。
長時間接続を維持しなければならないので、有線接続の上、電源に接続し、スリープしない設定にすることを推奨します。

```
XCODE_VERSION=14.2
MACOS_VERSION=13.2
gcloud auth print-access-token | tart login asia-northeast1-docker.pkg.dev --username oauth2accesstoken --password-stdin
tart clone asia-northeast1-docker.pkg.dev/omega-fabric-148305/monoxer-ghactions/macos-ventura-monoxer:$TAG ventura-monoxer:$TAG
```