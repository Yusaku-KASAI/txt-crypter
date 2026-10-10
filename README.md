# txt-crypter

パスフレーズでテキストを暗号化し、復号するための Web アプリ（Vue 3 と Vite。`vue/`）。

## アプリを動かす

```bash
make init   # 最初に一度
make up     # http://localhost:3000
make down
```

## 開発環境（devcontainer）

人の開発環境と、エージェントの実行環境を兼ねるコンテナ。ビルド、起動、停止はコマンドで行い、VS Code は
起動しているコンテナに入るだけにする（「Rebuild Container」は使わない）。

```bash
.devcontainer/init-host.sh                                   # ホストの準備（最初に一度。何度実行してもよい）
docker compose -f .devcontainer/compose.yaml up -d --build   # ビルドして起動する
docker compose -f .devcontainer/compose.yaml down            # 止める
```

起動したら VS Code の「Reopen in Container」で入る。`init-host.sh` は `.devcontainer/.env`（項目は
`.devcontainer/.env.example`）を書き、ログインや履歴を置くホストのディレクトリを作る。

## 検査

```bash
make check   # check-web（依存のインストールとビルド）と check-target（devcontainer のスクリプトと設定）
```

CI は検査ごとのジョブで、Dockerfile の同じ名前のステージをビルドする。必須のチェックは、結果をまとめる `check`。
