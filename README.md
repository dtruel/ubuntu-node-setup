# ubuntu-node-setup
A simple shell script to configure ubuntu. It installs:

- `Mongodb 3.2` - configures service to start automatically
- `Node LTS via NVM` - sets LTS version as default so `node` just works
- `Git`

It also sets timezone to UTC.

It tris to install postfix but fails.


```bash
wget https://raw.githubusercontent.com/dtruel/ubuntu-node-setup/master/setup.sh
chmod +x setup.sh
./setup.sh
```
