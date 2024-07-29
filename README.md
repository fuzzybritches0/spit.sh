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

Clone this repository:
```
git clone https://github.com/fuzzybritches0/spit.sh
```

Clone llama.cpp, compile the llama-cli executable and put it in the way of $PATH as well as spit.sh:
```
cd spit.sh
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make llama-cli
# To use CUDA run instead (install CUDA runtime, adjust spit.conf.sh to use your GPU - use option -ngl [LAYERS]):
GGML_CUDA=1 make llama-cli
ln -s ./llama-cli ~/bin/llama-cli
cd ..
ln -s ./spit.sh ~/bin/spit.sh
```

I prefer 8 bit quantisation. If you want to use a different quantisation, however, don't forget to adjust the settings in the spit.conf.sh.

Now, run it, like this:
```
spit.sh --id test_chat
```

In each spit.conf.sh, at the beginning, it will attempt to download the necessary gguf files, if they are not present. Make sure it will download the quantised version you prefer. Adjust as required. If the download is corrupted, and you encounter errors when loading the gguf file, remove it, and try again.

