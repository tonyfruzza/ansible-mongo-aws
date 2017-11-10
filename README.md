# MongoDB Replica Set in AWS

* Target OS support is CentOS 6
* Make use of tags for discovery of other machines
* Updates Route53 to create A records for nodes based on value of DNS-Name

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
  vars:
    hosted_zone_id: ABCDEFGHIJKLM
    assume_role_arn: 'arn:aws:iam::123456789101:role/Route53UpdaterRole'
    mongo_rep_set_name: reps

```
