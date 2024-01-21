# spit.sh

This script let's you chat with Large Language Models (gguf format) on the console using the great llama.cpp by Georgi Gerganov.

# Setup

Clone this repository:
```
git clone https://github.com/fuzzybritches0/spit.sh
```

Clone llama.cpp, compile the main executable and copy it into the sub-folder of your LLM in the examples folder:
```
cd spit.sh
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make main
cp main ../examples/openchat-3.5-0106 (or any other directory containing a valid spit.conf.sh file and the right gguf)
```
Next, download a compatible chat model from huggingface.co and place it in the examples sub-folder. Here follows a list of all the downloadable LLM models in the examples folder:
```
https://huggingface.co/TheBloke/dolphin-2.6-mistral-7B-dpo-laser-GGUF/tree/main
https://huggingface.co/TheBloke/medicine-chat-GGUF/tree/main
https://huggingface.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF/tree/main
https://huggingface.co/TheBloke/openchat-3.5-0106-GGUF/tree/main
https://huggingface.co/TheBloke/SOLAR-10.7B-Instruct-v1.0-GGUF/tree/main
```
I prefer 8 bit quantization. If you want to use a different quantization, however, don't forget to adjust the settings in the spit.conf.sh file. The PROG[@] array holds the name of the 8 bit quantized file name.

Now, run it, like this:
```
../../bin/spit.sh test_chat
```
