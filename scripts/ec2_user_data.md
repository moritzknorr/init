for copy purposes, please update in instance.json and keep in sync here

```
#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1 
wget https://raw.githubusercontent.com/moritzknorr/init/master/script/ec2.sh 
chmod +x ec2.sh 
./ec2.sh
```
