# cosci — AI co-scientist

cosci 是面向科研的 AI 助手：读写你的数据和代码、跑分析和实验、查文献与数据库，并给出带证据和不确定性说明的结论。这个仓库只发布安装包。

[English](#english)

## 安装

**Linux（x86_64，任意发行版）和 macOS（M 系列芯片 M1/M2/M3/M4，或 Intel 芯片）**

```sh
curl -fsSL https://raw.githubusercontent.com/harrysyz99/cosci/main/install.sh | sh
```

**Windows（x86_64，在 PowerShell 里运行）**

```powershell
irm https://raw.githubusercontent.com/harrysyz99/cosci/main/install.ps1 | iex
```

安装脚本会下载最新版本并校验 sha256。Linux 和 macOS 装到 `~/.local/lib/cosci`，并在 `~/.local/bin` 建一个 `cosci` 链接；Windows 装到 `%LOCALAPPDATA%\cosci`，并加进用户 PATH。暂不支持 ARM 版 Linux 和 Windows。

也可以在 [Releases](https://github.com/harrysyz99/cosci/releases) 手动下载对应平台的压缩包，里面的 `README.md` 有手动安装步骤。注意：

- Linux 包里的 `codex-resources/bwrap`、Windows 包里的 `codex-resources\` 是运行命令用的沙箱，必须和程序放在同一个目录。
- 这些版本没有代码签名。在 macOS 上用浏览器下载时，要先运行 `xattr -d com.apple.quarantine cosci` 才能打开；Windows 第一次运行可能弹出 SmartScreen 提示，选择"仍要运行"。用上面的安装脚本安装通常不会遇到这些提示。
- 不要装到 `~/.cosci/packages/` 下面。

## 登录

```sh
cosci login                    # 用 ChatGPT 账号，在浏览器里登录
cosci login --device-auth      # 通过 SSH 连服务器时用：在任意设备的浏览器里输入验证码
printenv OPENAI_API_KEY | cosci login --with-api-key   # 或者用 OpenAI API key
```

需要 OpenAI 账号，以及能访问 OpenAI 的网络。需要代理的话，先设置 `HTTPS_PROXY`。

## 使用自己的模型接口

只要接口实现了 OpenAI 的 Responses API（`POST /v1/responses`，流式输出），就可以直接接入，不用登录 ChatGPT：

```toml
# ~/.cosci/config.toml
model = "你的模型名"
model_provider = "mylab"
model_context_window = 128000   # cosci 不认识的模型，需要告诉它上下文长度

[model_providers.mylab]
name = "My lab endpoint"
base_url = "https://llm.example.org/v1"
env_key = "MYLAB_API_KEY"       # cosci 从这个环境变量读取 API key
wire_api = "responses"
```

在终端里设置好 `MYLAB_API_KEY`，照常运行 `cosci` 即可。不支持 Chat Completions（`wire_api = "chat"`）：只提供 `/v1/chat/completions` 的接口，需要在前面加一个提供 Responses API 的网关。可以这样检查接口是否支持：

```sh
curl https://llm.example.org/v1/responses -H "Authorization: Bearer $MYLAB_API_KEY" \
  -H "Content-Type: application/json" -d '{"model": "你的模型名", "input": "hi"}'
```

## 把对话同步到 WebDAV

cosci 可以把每次对话和审计记录同步到 WebDAV 目录（Nextcloud、ownCloud 或其他 WebDAV 服务）。本地文件始终是主副本，上传失败不会丢数据。在交互界面里用 `/cloud` 设置，或者写进配置：

```toml
# ~/.cosci/config.toml
[transcript_cloud]
provider = "webdav"
url = "https://drive.example.org/lab-folder/"
username = "lab-user"
password_env = "LAB_WEBDAV_PASSWORD"   # 密码从这个环境变量读取
```

审计记录里可能有敏感输入，请设置好 WebDAV 目录的访问权限。

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
rm -rf ~/.local/lib/cosci ~/.local/bin/cosci   # Linux、macOS；再删掉 ~/.cosci 会清除设置和会话记录
```

Windows：删掉 `%LOCALAPPDATA%\cosci`，并从用户 PATH 里去掉它；`%USERPROFILE%\.cosci` 里是设置和会话记录。

## 许可证

Apache-2.0，见 [LICENSE](LICENSE)。cosci 基于开源的 OpenAI Codex CLI 开发，见 [NOTICE](NOTICE)。

---

<a id="english"></a>

## English

cosci is an AI co-scientist: it works with your data and code, runs analyses and experiments, searches literature and databases, and reports conclusions with evidence and uncertainty. This repository hosts binary releases.

**Install.** Linux (x86_64, any distribution) and macOS (M-series chips M1/M2/M3/M4, or Intel):

```sh
curl -fsSL https://raw.githubusercontent.com/harrysyz99/cosci/main/install.sh | sh
```

Windows (x86_64, in PowerShell):

```powershell
irm https://raw.githubusercontent.com/harrysyz99/cosci/main/install.ps1 | iex
```

The scripts download the latest release and verify its sha256. To install by hand, download your platform's archive from [Releases](https://github.com/harrysyz99/cosci/releases) and follow the README inside. Keep `codex-resources` (the command sandbox on Linux and Windows) next to the program. The builds are not code-signed: on macOS, run `xattr -d com.apple.quarantine cosci` after a browser download; on Windows, SmartScreen may warn on first run. The install scripts usually avoid both.

**Sign in** with `cosci login` (ChatGPT account in a browser), `cosci login --device-auth` (over SSH), or `printenv OPENAI_API_KEY | cosci login --with-api-key`. You need an OpenAI account and network access to OpenAI; set `HTTPS_PROXY` if you use a proxy.

**Your own model endpoint.** Any endpoint that implements the OpenAI Responses API (`POST /v1/responses` with streaming) works without a ChatGPT sign-in: add a `[model_providers.<id>]` table with `base_url`, `env_key` (the variable holding your API key), and `wire_api = "responses"`, then set `model_provider` and `model` (see the TOML above). The Chat Completions API is not supported; put a Responses API gateway in front of chat-only endpoints.

**WebDAV mirroring.** cosci can copy each conversation and its audit transcript to a WebDAV folder (`/cloud` in the TUI, or `[transcript_cloud]` in `config.toml` as above). Local files stay the source of truth.

**Use** `cosci` (interactive), `cosci exec "…"` (one-shot; add `--skip-git-repo-check` outside a git repository), or `cosci web` (browser UI). Built-in tools query UniProt, RCSB PDB, and NCBI BLAST, and ask before sending your sequence to NCBI or RCSB. Settings and data live in `~/.cosci/`.

**License:** Apache-2.0 ([LICENSE](LICENSE)). cosci is derived from the open-source OpenAI Codex CLI ([NOTICE](NOTICE)).
