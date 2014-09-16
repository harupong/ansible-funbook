# Ansible-funbook - have fun with ansible

Ansible で遊ぼう。Radiko 予約録音サーバーを Linode に自動で立ててみる。

## 目的

Ansible のコントロールマシンで Radiko 予約録音すればいいじゃん、というのはごもっともなのだけど、悲しいことに自分の使ってるサーバーは Radiko の地域制限にひっかかってる。

Linode の Tokyo リージョンは Radiko の地域制限にひっかからず、かつ時間割りの課金に対応しており、うまく使えば安くあげられそう。

### Radiko 予約録音の流れ

ケチケチ運用なので、録音が終わったら Linode のインスタンスは削除したい。よって、録音したファイルは Dropbox に転送する。

1. レンタルサーバーの Cron を使って、Linode を録音実行日時の1時間前に立ち上げる
2. Ansible で Radiko 録音用のセットアップを行う
3. ripdiko を使って Radiko を録音する
4. ripdiko の事後処理機能を使って以下の処理を行う
    - dropbox_uploader.sh で録音ファイルを Dropbox に転送する
    - linode-cli で立ち上げた Linode のインスタンスを削除する

Dropbox のファイルは [CloudBeats](https://itunes.apple.com/jp/app/cloudbeats-kuraudo-yin-lepureiya/id573192227?mt=8) のような iOS アプリで直接再生してもよし、[Zapier](https://zapier.com/) を使って Podcast Feed 化してもよし。

## 予約録音サーバーを作る
### 作業フォルダを作る

```
git pull https://github.com/harupong/ansible-funbook
cd ansible-funbook
```

### 必要なソフトウェアをインストールする

Ansible のコントロールマシン(制御する側)に必要なソフトウェア：

- Ansible
- jq
- linode-cli
- Dropbox-Uploader

制御される側(今回は Linode)には何もいれなくていい(Python が入ってればOK)。

#### Ansible をインストール

Linode のインスタンスをセットアップするのに使う。インストール手順 -> http://docs.ansible.com/intro_installation.html#id11

```
$ sudo apt-get install software-properties-common
$ sudo apt-add-repository ppa:ansible/ansible
$ sudo apt-get update
$ sudo apt-get install ansible
```

#### linode-cli のインストール

Linode をコマンドラインで操作するのに使う。インストール手順 -> https://github.com/linode/cli

```
sudo bash -c 'echo "deb http://apt.linode.com/ stable main" > /etc/apt/sources.list.d/linode.list'
wget -O- https://apt.linode.com/linode.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install linode-cli
```

#### jq のインストール

Linode から取得する JSON をパースするのに使う。

```
sudo apt-get install jq
```

#### Dropbox-Uploader をインストール

Linode のインスタンスから録音したファイルを Dropbox に転送するのに使う。インストール手順 -> https://github.com/andreafabrizi/Dropbox-Uploader#getting-started

```
curl "https://raw.github.com/andreafabrizi/Dropbox-Uploader/master/dropbox_uploader.sh" -o dropbox_uploader.sh
chmod +x dropbox_uploader.sh
```

### 初期設定
#### 専用の鍵ペア

Ansible が Linode のインスタンスと SSH 接続するのに使う。

```
ssh-keygen -N "" -f ~/.ssh/id_rsa.linode
```

#### Ansible の設定

作業フォルダにある設定ファイル `.ansible.cfg` にホームディレクトリからシンボリックリンクを張る。

```
cd ~/
ln -s /path/to/.ansible.cfg .ansible.cfg
```

<!--
`.ansible.cfg` から以下を uncomment し、かつ下の3つはパラメーターを追記する。

```
host_key_checking = False
log_path = /path/to/ansible-funbook/ansible.log
sudo_user = root
private_key_file = ~/.ssh/id_rsa.linode
```
-->

#### linode-cli の設定

```
linode configure
```

で初期設定ウィザードを立ち上げる。Linode の ID とパスワードを入れると API Key を取得して設定ファイル `~/.linodecli/config` に保存してくれる。

他の設定は好みで入れるか、全てスキップしたうえで設定ファイルに以下を貼り付けてもOK。

```
distribution Ubuntu 13.10
datacenter tokyo
plan Linode 1024
pubkey-file ~/.ssh/id_rsa.linode.pub
```

あと、環境変数を1つ

```
echo 'export LINODE_PASSWORD="<password>"' >> ~/.bash_profile
```

で設定しておく。`linode create <instance-name>` したときに `--password $LINODE_PASSWORD` とオプションをつけることで、Linode インスタンスの root パスワードを入力するプロンプトが出るのを抑制したいので。

#### Dropbox-uploader の設定

```
./dropbox_uploader.sh
```

すると初期設定ウィザードが立ち上がり、Dropbox API の設定が始まる。画面の指示に従って Sandbox タイプのアプリとして登録すると、oAuth の処理をしてトークンなどを `~/.dropbox_uploader` に保存してくれる。

#### Cron 設定

`crontab -e` を使って以下のエントリーを Cron ジョブとして追加する。時刻は録画したい番組の開始1時間前。

```
## Launch Linode instance for recording XYZ
0 0 * * * /bin/bash -l -c '/path/to/ansible-funbook/linode_ripdiko.sh > /path/to/ansible-funbook/linode_ripdiko.log 2>&1'
```

#### ripdiko 用のAnsible-playbook
#### ripdiko 用の recording_finished スクリプト

