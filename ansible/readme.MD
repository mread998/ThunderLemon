# Building and Using a Custom AWX Execution Environment (EE)

This document explains how to:

1. Build a custom **AWX Execution Environment (EE)**
2. Push the image to an internal **container registry**
3. Register the EE in **AWX**
4. Use the EE in **AWX Job Templates**

This workflow assumes:

* AWX is running in **Kubernetes/k3s**
* An internal registry exists (example: `registry.thundertest.org`)
* TLS is configured for the registry
* Nodes and build host trust the registry CA

---

# 1. Prerequisites

On the **build host (bastion)** install the required tools:

```bash
sudo apt update
sudo apt install -y python3-pip python3-venv podman buildah
```

Create a Python virtual environment:

```bash
mkdir ~/awx-ee
cd ~/awx-ee

python3 -m venv venv
source venv/bin/activate
```

Install **ansible-builder**:

```bash
pip install ansible-builder
```

Verify installation:

```bash
ansible-builder --version
```

---

# 2. Create the Execution Environment Definition

Create the file:

```
execution-environment.yml
```

Example:

```yaml
version: 3

images:
  base_image:
    name: quay.io/ansible/awx-ee:latest

dependencies:
  ansible_core:
    package_pip: ansible-core
  ansible_runner:
    package_pip: ansible-runner
  galaxy: requirements.yml
  system:
    - gcc
    - python3-devel
    - libxml2-devel
```

---

# 3. Define Required Ansible Collections

Create:

```
requirements.yml
```

Example:

```yaml
collections:
  - name: community.general
  - name: ansible.posix
  - name: kubernetes.core
  - name: community.docker
```

These collections will be installed into the EE during build.

---

# 4. Build the Execution Environment

From the project directory:

```bash
cd ~/awx-ee
rm -rf context

sudo -E $(which ansible-builder) build \
  -t registry.thundertest.org/awx-ee:2026.03 \
  --container-runtime podman
```

This process will:

1. Pull the base image
2. Install Ansible and Ansible Runner
3. Install collections from Ansible Galaxy
4. Install required system dependencies
5. Build the final container image

---

# 5. Verify the Image

Before pushing, verify the image works:

```bash
sudo podman run --rm registry.thundertest.org/awx-ee:2026.03 ansible --version

sudo podman run --rm registry.thundertest.org/awx-ee:2026.03 ansible-galaxy collection list
```

Confirm the required collections appear.

---

# 6. Push the Image to the Registry

If the registry requires authentication:

```bash
sudo podman login registry.thundertest.org
```

Push the image:

```bash
sudo podman push registry.thundertest.org/awx-ee:2026.03
```

---

# 7. Configure the Registry (If Using NGINX Ingress)

To allow large container uploads, ensure the registry ingress includes:

```yaml
annotations:
  nginx.ingress.kubernetes.io/proxy-body-size: "0"
  nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
  nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
  nginx.ingress.kubernetes.io/proxy-request-buffering: "off"
  nginx.ingress.kubernetes.io/proxy-buffering: "off"
```

Without this configuration, large pushes may fail with `broken pipe`.

---

# 8. Add the Execution Environment to AWX

In the AWX web interface:

Navigate to:

```
Administration → Execution Environments → Add
```

Fill in:

| Field       | Value                                   |
| ----------- | --------------------------------------- |
| Name        | awx-ee                                  |
| Image       | registry.thundertest.org/awx-ee:2026.03 |
| Pull Policy | Always                                  |

Save the Execution Environment.

---

# 9. Attach the EE to a Job Template

Open the relevant **Job Template** in AWX and set:

```
Execution Environment: awx-ee
```

Save the template.

---

# 10. Test the Execution Environment

Run a simple test playbook:

```yaml
---
- name: Test Execution Environment
  hosts: all
  gather_facts: false

  tasks:
    - name: Show Ansible version
      command: ansible --version
      register: output

    - debug:
        var: output.stdout_lines
```

This confirms AWX is running jobs using the custom EE.

---

# Recommended Practices

### Version your images

Instead of always using `latest`, tag builds:

```
registry.thundertest.org/awx-ee:2026.03
registry.thundertest.org/awx-ee:2026.04
```

This prevents breaking existing job templates.

### Store build files in Git

Example repository structure:

```
infra/
 └── awx-ee/
      ├── execution-environment.yml
      └── requirements.yml
```

This allows reproducible builds and easier updates.

### Future improvements

You may want to include additional tools for automation such as:

* kubectl
* helm
* jq
* yq

These can be added via `system` or `additional_build_steps` in the EE definition.

---

# Summary

The workflow is:

1. Define EE configuration
2. Build with `ansible-builder`
3. Push image to registry
4. Register EE in AWX
5. Assign EE to job templates

This enables AWX to run playbooks with all required modules and dependencies packaged in a consistent runtime environment.
