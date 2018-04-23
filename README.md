# twentythousandphantoms_infra

## Homework 04 (cloud-bastion)

#### 0. Connection config
bastion_IP=35.187.186.203
someinternalhost_IP=10.132.0.3

#### 1. Single string connection
...to someinternalhost through bastion 

`ssh -i ~/.ssh/appuser -o ProxyCommand="ssh -i ~/.ssh/appuser -W %h:%p appuser@35.187.186.203" appuser@10.132.0.3`
or add key to ssh-agent and `ssh -A -t appuser@35.187.186.203 ssh 10.132.0.3`
#### 2. SSH aliases
...that allows connect via `ssh someinternalhost`
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
## Homework 05 (cloud-testapp)

#### 0. Connection config
testapp_IP = 23.251.142.164
testapp_port = 9292

#### 1.a Deploy test reddit-app via [gcloud][1] command-line tool and [local startapp script file][2]
```
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup_script.sh 
```
#### 1.b Deploy test reddit-app via [gcloud][1] command-line tool and [startup script url][3] to access your startup script from anywhere

Create bucket in Cloud Storage and copy startup script into bucket
```
gsutil mb gs://my-awesome-infra-199712-bucket/
gsutil cp startup_script.sh gs://my-awesome-infra-199712-bucket
```
Deploy command
```
gcloud compute instances create reddit-app \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags default-puma-server \
  --restart-on-failure \
  --scopes storage-ro \
  --metadata startup-script-url=gs://my-awesome-infra-199712-bucket/startup_script.sh
```
#### 1.2 Delete test reddit-app instance
```
gcloud compute instances delete reddit-app
```
#### 2. Create a Google Compute Engine [firewall rule][4] 
```
gcloud compute firewall-rules create default-puma-server\
  --allow tcp:9292 \
  --target-tags puma-server
```
#### 2.1 Delete the rule
```
gcloud compute firewall-rules delete default-puma-server
```

[1]: https://cloud.google.com/sdk/gcloud/
[2]: https://cloud.google.com/compute/docs/startupscript#using_a_local_startup_script_file
[3]: https://cloud.google.com/compute/docs/startupscript#cloud-storage
[4]: https://cloud.google.com/sdk/gcloud/reference/compute/firewall-rules/create

## Homework 06 (packer)

#### 0. Get Packer 
[Get][5] Packer, unzip into any $PATH directory, check with `packer -v`

#### 1. Create GCP Application Default Credentials (ADC)
Create [ADC][6] to allow your app or third-party tools (Packer) to manage GCP.
```
gcloud auth application-default login
```

#### 2.a Create a Packer template and build the image with preinstalled Ruby and MongoDB
[Read about Packer configuration options][7] for type: "googlecompute".

See `./packer/ubuntu16.json` and `./packer/variables.json` templates

Build (use your proj_id):
```
cd packer && packer build \
  -var='proj_id=infra-199712' \
  -var='source_image_family=ubuntu-1604-lts' \
  -var-file=variables.json \
  ubuntu16.json
```
Look at the list of images:
```
$ gcloud compute images list --filter reddit
NAME                    PROJECT       FAMILY       DEPRECATED  STATUS
reddit-base-1524503552  infra-199712  reddit-base              READY
```
This image allows you to create instanses like that:
```
gcloud compute instances create reddit-app \
  --image=reddit-base-1524503552 \
  --machine-type=g1-small \
  --tags=default-puma-server \
  --metadata-from-file \
  startup-script=config-scripts/deploy.sh
```
#### 2.b Create a Packer template and build the immutable image with entirely app (reddit)
There are [Immutable Infrastructure methodology][8]. Read about [immutable servers][9].

See `packer/immutable.json`

Bake the image with command:
```
cd packer && \
packer build \
  -var-file=variables.json \
  -var='proj_id=infra-199712' \
  -var='source_image_family=ubuntu-1604-lts' \
  immutable.json
```
Then create immutable instance with script:
```
$ sh config-scripts/create-reddit-vm.sh
```
and get running reddit-app in few seconds (on EXTERNAL_IP:9292)


[5]: https://www.packer.io/downloads.html
[6]: https://cloud.google.com/compute/docs/api/how-tos/authorization#gcloud_auth_login
[7]: https://www.packer.io/docs/builders/googlecompute.html
[8]: https://www.oreilly.com/ideas/an-introduction-to-immutable-infrastructure
[9]: https://martinfowler.com/bliki/ImmutableServer.html
