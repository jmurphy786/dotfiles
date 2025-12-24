#  If you want to setup ssh to connect to your github account  

## SSH setup

```bash

ssh-keygen -t ed25519 -C "your_email@example.com"

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

cat ~/.ssh/id_ed25519.pub


```


## Setting up dual sign in for personal / other ssh

***tbd***

