# 開発の手順

## アプリを動かす

```bash
make init   # 最初に一度
make up     # http://localhost:3000
make down
```

## 開発環境（devcontainer）

人の開発環境とエージェントの実行環境を兼ねる devcontainer の使い方は、target-template の
[devcontainer の使い方](https://github.com/Yusaku-KASAI/agent-control-plane/blob/main/template/docs/guides/devcontainer.md)
のとおり。

## 検査

```bash
make check   # check-web（依存のインストールとビルド）、check-target（devcontainer）、check-docs（文書）
```

CI は検査ごとのジョブで、`.devcontainer/Dockerfile` の同じ名前のステージをビルドする。必須のチェックは、結果を
まとめる `check`。
