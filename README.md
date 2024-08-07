# spit.sh

This script let's you chat with Large Language Models (gguf format) on the console using the great llama.cpp by Georgi Gerganov <https://github.com/ggerganov/llama.cpp>.

```
HELP
----
spit.sh v0.0.2

spit.sh [ -h || --help ]
spit.sh [ --id CHAT_SESSION_ID ] [ --sysid SYSTEM_ID ] [ INPUT ]

CHAT_ID           an identifier for a new or existing chat session (mandatory)
SYSTEM_ID         a numeric identifier for the system prompt (if omitted '0' is assumed)
INPUT             INPUT non-interactively
-h|--help         show this here help screen
```

# Setup

Clone this repository and put spit.sh in the way of your $PATH:
```
git clone https://github.com/fuzzybritches0/spit.sh
cd ~/bin
ln -s ../path_to_your_copy_of/spit.sh/bin/spit.sh spit.sh
```

Clone llama.cpp, compile the llama-cli executable and put it in the way of your $PATH:
```
cd spit.sh
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make llama-cli
# To use CUDA run instead (install CUDA runtime, adjust spit.conf.sh to use your GPU - use option -ngl [LAYERS]):
GGML_CUDA=1 make llama-cli
cd ~/bin
ln -s ../paht_to_your_copy_of/llama.cpp/llama-cli llama-cli
```

I prefer 8 bit quantisation. If you want to use a different quantisation, however, don't forget to adjust the settings in spit.conf.sh.

Now, run it, like this:
```
spit.sh --id test_chat
```

In each spit.conf.sh, at the beginning, it will attempt to download the necessary gguf files, if they are not present. Make sure it will download the quantised version you prefer. Adjust as required. If the download is corrupted, and you encounter errors when loading the gguf file, remove it, and try again.

For the WIKI function to work, you need <https://github.com/fuzzybritches0/wiki-cli>. Clone it and put the wiki-cli script in the way of your $PATH.

For the READ_URL function you need w3m to be installed (apt install w3m). For the SEARCH function you need ddgr to be installed (apt install ddgr).
