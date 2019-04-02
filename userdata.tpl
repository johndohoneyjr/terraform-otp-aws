#! /bin/bash
wget https://releases.hashicorp.com/vault-ssh-helper/0.1.4/vault-ssh-helper_0.1.4_linux_amd64.zip

# Unzip the vault-ssh-helper in /user/local/bin
sudo unzip -q vault-ssh-helper_0.1.4_linux_amd64.zip -d /usr/local/bin

# Make sure that vault-ssh-helper is executable
sudo chmod 0755 /usr/local/bin/vault-ssh-helper

# Set the usr and group of vault-ssh-helper to root
sudo chown root:root /usr/local/bin/vault-ssh-helper

sudo mkdir -p /etc/vault-ssh-helper.d
sudo touch /etc/vault-ssh-helper.d/config.hcl
sudo dd of=/etc/vault-ssh-helper.d/config.hcl << EOF
vault_addr = "127.0.0.1:8200"
ssh_mount_point = "ssh"
ca_cert = "/etc/vault-ssh-helper.d/vault.crt"
tls_skip_verify = false
allowed_roles = "*"
EOF

mkdir -p /etc/pam.d
sudo touch /etc/pam.d/sshd
sudo dd of=/etc/pam.d/sshd << EOF
auth requisite pam_exec.so quiet expose_authtok log=/tmp/vaultssh.log /usr/local/bin/vault-ssh-helper -dev -config=/etc/vault-ssh-helper.d/config.hcl
auth optional pam_unix.so not_set_pass use_first_pass nodelay
EOF

mkdir -p /etc/ssh
sudo touch /etc/ssh/sshd_config
sudo dd of=/etc/ssh/sshd_config << EOF
ChallengeResponseAuthentication yes
PasswordAuthentication no
UsePAM yes
EOF

sudo systemctl restart sshd
sudo dd of=/home/centos/test << EOF
#! /bin/bash
echo "Test"
echo
EOF
