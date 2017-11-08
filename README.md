### Assuming ansible is installed
```
mkdir -p /etc/ansible
cat > /etc/ansible/hosts << EOF
[mongodb]
localhost
EOF

mkdir -p /usr/local/src/roles
cd /usr/local/src/roles
git clone https://github.com/tonyfruzza/ansible-mongo-aws.git mongodb
cd ..
ansible-playbook playbook.yml --connection=local
```

### Sample playbook.yml
```
- hosts: localhost
  connection: local
  roles:
    - mongodb
```