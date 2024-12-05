{
  "name": "k8s-master",
  "region": "nyc3",
  "size": "s-2vcpu-2gb",
  "image": "ubuntu-24-10-x64",
  "backups": false,
  "user_data": "#!/bin/bash
git clone https://github.com/MuhammetSoil/ks.git
cd ks
chmod +x kubev2.sh
chmod +x jenkins.sh
chmod +x argocd.sh
yes | ./kubev2.sh
yes | ./argocd.sh
yes | ./jenkins.sh"
}

# post