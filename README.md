# elasticsearch-docker
Another docker image for Elasticsearch based on official docker image with SearchGuard and Azure(Snapshot/Restore) integration. Kopf & Elastic HQ plugins are also included.

Click here for the [Docker Repository](https://hub.docker.com/r/iboware/elasticsearch/)

###How to initialize the image from docker hub:
```bash
sudo docker run -d -p 9200:9200 -p 9300:9300 \
-v /some/folder/or/volume:/usr/share/elasticsearch/data \
-v /some/folder/or/volume:/usr/share/elasticsearch/config \
-v /usr/share/elasticsearch/config/scripts \
--name es iboware/elasticsearch
```

###Sample elasticsearch.yml configuration file
It includes cloud-azure addon configuration for snapshot/restore and default search-guard configuration for basic authentication. **_You should include all of your search-guard configuration files together with truststore.jks and keystore.jks certificates under the config directory defined above._**

For more details about search-guard and how to generate demo certificates follow this link:
[search-guard-ssl quickstart](https://github.com/floragunncom/search-guard-ssl-docs/blob/master/quickstart.md])

```yml
#3 Node ElasticSearch Cluster configuration
cluster.name: Federation
node.name: Vulcan
network.host: 0.0.0.0
discovery.zen.ping.unicast.hosts: ["vulcan","andoria","earth"]
discovery.zen.minimum_master_nodes: 2
#Azure Configuration
cloud.azure.storage.arbitaryname.account: 'somestorageaccount'
cloud.azure.storage.arbitaryname.key: 'storageaccountkey'
#SearchGuard Configuration
searchguard.ssl.transport.keystore_filepath: /usr/share/elasticsearch/config/node-0-keystore.jks
searchguard.ssl.transport.keystore_password: changeit
searchguard.ssl.transport.truststore_filepath: /usr/share/elasticsearch/config/truststore.jks
searchguard.ssl.transport.truststore_password: changeit
searchguard.ssl.transport.enforce_hostname_verification: false
searchguard.authcz.admin_dn:
  - "CN=kirk,OU=client,O=client,L=Test,C=DE"
```

### How to initialize or update your search-guard configuration
First execute bash from one of your elasticsearch nodes.
```bash
sudo docker exec -i -t yourelasticsearch /bin/bash
```
Secondly execute those commands to initialize default config on your node. If you are running a cluster, this settings will be applied to all of your nodes. For more details please check [search-guard installation](https://github.com/floragunncom/search-guard/wiki/Installation)
```bash
chmod +x /usr/share/elasticsearch/plugins/search-guard-2/tools/sgadmin.sh
plugins/search-guard-2/tools/sgadmin.sh \
-cd /usr/share/elasticsearch/config \ 
-ks /usr/share/elasticsearch/config/kirk-keystore.jks \
-ts /usr/share/elasticsearch/config/truststore.jks \
-cn NameOfYourCluster \ 
-nhnv 
```
