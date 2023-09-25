# spit.sh

# Setup

Clone this repository:
```
git clone https://github.com/fuzzybritches0/spit.sh
```

Clone llama.cpp, compile the main executable and copy it into the examples/llama-13b-chat folder:
```
cd spit.sh
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp
make main
cp main ../examples/llama-13b-chat
```
Next, download a compatible llama2 chat model from huggingface.co and place it in the examples/llama-13b-chat folder, like so:
```
cd ../examples/llama-13b-chat
wget -c https://huggingface.co/TheBloke/Llama-2-13B-chat-GGUF/resolve/main/llama-2-13b-chat.Q8_0.gguf
```

Now, run it, like this:
```
../../bin/spit.sh test_chat
```
