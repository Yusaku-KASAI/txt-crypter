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

CI の仕組みは、target-template の [CI](https://github.com/Yusaku-KASAI/agent-control-plane/blob/main/template/docs/architecture/ci.md) の説明のとおり。

## Vue のプロジェクトを作り直す

`vue/` を作り直すときの手順。`make front-create` の途中で、対話で答える。

1. `.dockerignore` の `vue/node_modules` をコメントアウトする。
2. `make front-create` を実行する。プロジェクト名は `.`（今のディレクトリ）、パッケージ名はプロジェクトの名前にする。
3. `.dockerignore` の `vue/node_modules` のコメントを戻し、`make reset` を実行する。
4. `vite.config.js` のサーバーの設定で `host: true` にし、起動を確かめて、要ればポートを変える。
5. 作られた `vue/README.md`（create-vue のひな形の説明）を消す。動かし方はこの文書にある。
