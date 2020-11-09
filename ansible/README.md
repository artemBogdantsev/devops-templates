# Ansible Provisioner

This sub-project contains the needed information to get started with provisioning GCE instances with Ansible.

## Install

#### 1. [Install Ansible with PIP](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#from-pip)
#### 2. Run 
```bash
$ ansible --version
ansible 2.9.9
  config file = None
  configured module search path = [u'/Users/botem/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /Library/Python/2.7/site-packages/ansible
  executable location = /usr/local/bin/ansible
  python version = 2.7.16 (default, Apr 17 2020, 18:29:03) [GCC 4.2.1 Compatible Apple LLVM 11.0.3 (clang-1103.0.29.20) (-macos10.15-objc-
```
#### 3. Requisites
The GCP modules require both the `requests` and the `google-auth libraries to be installed.
```bash
$ pip install requests google-auth
``` 

## Credentials 
It’s easy to create a GCP account with credentials for Ansible. You have multiple options to get your credentials - here are two of the most common options:

* Service Accounts (Recommended): Use JSON service accounts with specific permissions.
* Machine Accounts: Use the permissions associated with the GCP Instance you’re using Ansible on.
For the following examples, we’ll be using service account credentials.

To work with the GCP modules, you’ll first need to get some credentials in the JSON format:

1. Create a Service Account
2. Download JSON credentials

Once you have your credentials, there are two different ways to provide them to Ansible:

* by specifying them directly as module parameters
* by setting environment variables

Note: more info at official [Ansible doc](https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html#credentials)
