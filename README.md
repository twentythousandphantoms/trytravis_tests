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

## Homework 07 (terrafrom)
Here we described infrastructure using [terraform][10]. In terraform/main.tf there are thee resources described: metadata (ssh-keys), instance and firewall rule.

### *

Notes about ssh-keys adding:
1. If there are multiple SSH keys, each key will be separated by a newline character (\n). But if use macro, don't need to use any separator. Example: terraform/main.tf 
2. `Error, key 'ssh-keys' already exists in project 'infra-199712'` — keys that I added earlier through web-console. So, to continue, I deleted it. 
3. After adding key using terraform you must add ones only using terraform further. Otherwise, the next time you start terrafrom, it will erase keys.

### **

Also [HTTP Load Balancer][27] is added with configuration described in lb.tf.
There are several entities(components) that must be described for succesful launching the LB:
* instances (Docs: [Terraform][11], [GCP][19])
* unmanaged_instance_group (Docs: [Terraform][12], [GCP][20])
* backend (Docs: [Terraform][13], [GCP][21])
* backend_service (Docs: [Terraform][14], [GCP][22])
* health_check (Docs: [Terraform][15], [GCP][23])
* url_map (Docs: [Terraform][16], [GCP][24])
* target_http_proxy (Docs: [Terraform][17], [GCP][25])
* finally, global_forwarding_rule (Docs: [Terraform][18], [GCP][26])

[10]: https://www.terraform.io/docs/providers/google/r/compute_instance.html
[11]: https://www.terraform.io/docs/providers/google/r/compute_instance.html
[12]: https://www.terraform.io/docs/providers/google/r/compute_instance_group.html
[13]: https://www.terraform.io/docs/providers/google/r/compute_backend_service.html#backend
[14]: https://www.terraform.io/docs/providers/google/r/compute_backend_service.html
[15]: https://www.terraform.io/docs/providers/google/r/compute_health_check.html
[16]: https://www.terraform.io/docs/providers/google/r/compute_url_map.html
[17]: https://www.terraform.io/docs/providers/google/r/compute_target_http_proxy.html
[18]: https://www.terraform.io/docs/providers/google/r/compute_global_forwarding_rule.html
[19]: https://cloud.google.com/compute/docs/instances/
[20]: https://cloud.google.com/compute/docs/instance-groups/#unmanaged_instance_groups
[21]: https://cloud.google.com/compute/docs/load-balancing/http/
[22]: https://cloud.google.com/compute/docs/load-balancing/http/backend-service
[23]: https://cloud.google.com/compute/docs/load-balancing/health-checks
[24]: https://cloud.google.com/compute/docs/load-balancing/http/url-map
[25]: https://cloud.google.com/compute/docs/load-balancing/http/target-proxies
[26]: https://cloud.google.com/compute/docs/load-balancing/http/global-forwarding-rules
[27]: https://cloud.google.com/compute/docs/load-balancing/http/

## Homework 08 (terrafrom-2)

App, Db and VPC terraform are placed in modules. [Modules][28] allows to reuse the code in various cases, such as different enviroments. So "prod" and "stage" enviroments are created. 

### *

Terraform [state file][29] storage was moved from local to remote. The [Google Cloud Storage][30] is created and ["backend"][31] is configured for that. It supports [State Storage and Locking][32]. From now on it is possible to work in team without fear of damage to the infrastructure as a result of the one-time launch "terraform apply" from different places.

[28]:https://www.terraform.io/docs/modules/index.html
[29]:https://www.terraform.io/docs/state/index.html
[30]:https://www.terraform.io/docs/backends/types/gcs.html
[31]:https://www.terraform.io/docs/backends/index.html
[32]:https://www.terraform.io/docs/backends/state.html
[29]:https://www.terraform.io/docs/state/

### **

Provisioners for deploy reddit-app are configured. 

## Homework 01 (ansible-1)

Ansible initiated, inventory created, first playbook "Clone" added.
ANsible have a good reports about what it really changes or not.

### * 

Also inventory.json and inventory.sh placed that simulates [dynamic inventory][33].  

[33]: https://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html
