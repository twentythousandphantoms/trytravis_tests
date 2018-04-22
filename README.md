# twentythousandphantoms_infra

## Homework 04

bastion_IP=35.187.186.203

someinternalhost_IP=10.132.0.3

#### Подключение одной строкой
к someinternalhost через bastion 

a) MacOS:

`ssh -i ~/.ssh/appuser -o ProxyCommand="ssh -i ~/.ssh/appuser -W %h:%p appuser@35.187.186.203" appuser@10.132.0.3`

b) Ubuntu 16.04:

Добавить ключ в ssh-agent и `ssh -A -t appuser@35.187.186.203 ssh 10.132.0.3`
####  `ssh someinternalhost`
Содержимое `~/.ssh/config` для подключения командой вида `ssh someinternalhost`:
```
Host *
ForwardAgent yes

Host bastion
User appuser
HostName 35.187.186.203

Host someinternalhost
User appuser
HostName 10.132.0.3
ProxyCommand ssh bastion nc %h %p
```
