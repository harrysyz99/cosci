# cosci — AI co-scientist

cosci 是面向科研的 AI 助手：读写你的数据和代码、跑分析和实验、查文献与数据库，并给出带证据和不确定性说明的结论。这个仓库只发布安装包。

[English](#english)

## 安装

支持任意 x86_64 Linux（静态编译，不依赖系统库）：Ubuntu、Debian、CentOS/RHEL、各类计算集群都可以。暂不支持 macOS、Windows 和 ARM。

```sh
curl -fsSL https://raw.githubusercontent.com/harrysyz99/cosci/main/install.sh | sh
```

脚本会下载最新版本，校验 sha256，把程序装到 `~/.local/lib/cosci`，并在 `~/.local/bin` 建一个 `cosci` 链接。

也可以手动安装：在 [Releases](https://github.com/harrysyz99/cosci/releases) 下载 `cosci-*-x86_64-linux.tar.gz`，然后：

```sh
tar -xzf cosci-*-x86_64-linux.tar.gz
cd cosci-*-x86_64-linux
mkdir -p ~/.local/lib/cosci ~/.local/bin
cp -r cosci codex-resources ~/.local/lib/cosci/
ln -sf ~/.local/lib/cosci/cosci ~/.local/bin/cosci
```

`codex-resources/bwrap` 是运行命令时用的沙箱，必须和 `cosci` 放在同一个目录。不要装到 `~/.cosci/packages/` 下面。

## 登录

```sh
cosci login                    # 用 ChatGPT 账号，在浏览器里登录
cosci login --device-auth      # 通过 SSH 连服务器时用：在任意设备的浏览器里输入验证码
printenv OPENAI_API_KEY | cosci login --with-api-key   # 或者用 OpenAI API key
```

需要 OpenAI 账号，以及能访问 OpenAI 的网络。需要代理的话，先设置 `HTTPS_PROXY`。

## 使用

```sh
cd 你的项目目录
cosci                          # 交互界面
cosci exec "总结 data/ 里实验结果的主要发现"   # 非交互，跑完就退出
cosci web                      # 浏览器界面
```

目录不是 git 仓库时，`cosci exec` 需要加 `--skip-git-repo-check`；交互界面会先问你是否信任这个目录。

- 在交互界面里用 `/research` 设置研究领域、引用要求和数据源。
- 自带 UniProt、RCSB PDB、NCBI BLAST 查询。BLAST 和 PDB 序列搜索会把序列发给 NCBI 或 RCSB，运行前会先征求你的同意。
- `cosci colab submit` 可以把脚本放到 Google Colab 的 GPU/TPU 上运行。
- 设置和数据保存在 `~/.cosci/`。

## 卸载

```sh
rm -rf ~/.local/lib/cosci ~/.local/bin/cosci   # 再删掉 ~/.cosci 会清除设置和会话记录
```

## 许可证

Apache-2.0，见 [LICENSE](LICENSE)。cosci 基于开源的 OpenAI Codex CLI 开发，见 [NOTICE](NOTICE)。

---

<a id="english"></a>

## English

cosci is an AI co-scientist: it works with your data and code, runs analyses and experiments, searches literature and databases, and reports conclusions with evidence and uncertainty. This repository hosts binary releases.

**Install** (any x86_64 Linux; the build is static and needs no system libraries; no macOS, Windows, or ARM builds yet):

```sh
curl -fsSL https://raw.githubusercontent.com/harrysyz99/cosci/main/install.sh | sh
```

The script downloads the latest release, verifies its sha256, installs it in `~/.local/lib/cosci`, and links `~/.local/bin/cosci`. To install by hand, download `cosci-*-x86_64-linux.tar.gz` from [Releases](https://github.com/harrysyz99/cosci/releases) and copy `cosci` and `codex-resources/` into the same directory. `codex-resources/bwrap` is the command sandbox.

**Sign in** with `cosci login` (ChatGPT account in a browser), `cosci login --device-auth` (over SSH), or `printenv OPENAI_API_KEY | cosci login --with-api-key`. You need an OpenAI account and network access to OpenAI; set `HTTPS_PROXY` if you use a proxy.

**Use** `cosci` (interactive), `cosci exec "…"` (one-shot; add `--skip-git-repo-check` outside a git repository), or `cosci web` (browser UI). Built-in tools query UniProt, RCSB PDB, and NCBI BLAST, and ask before sending your sequence to NCBI or RCSB. Settings and data live in `~/.cosci/`.

**License:** Apache-2.0 ([LICENSE](LICENSE)). cosci is derived from the open-source OpenAI Codex CLI ([NOTICE](NOTICE)).
