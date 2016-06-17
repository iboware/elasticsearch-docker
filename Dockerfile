FROM iboware/oraclejdk8

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

# https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-repositories.html
# https://packages.elasticsearch.org/GPG-KEY-elasticsearch
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4

ENV ELASTICSEARCH_MAJOR 2.3
ENV ELASTICSEARCH_VERSION 2.3.3
ENV ELASTICSEARCH_REPO_BASE http://packages.elasticsearch.org/elasticsearch/2.x/debian

RUN echo "deb $ELASTICSEARCH_REPO_BASE stable main" > /etc/apt/sources.list.d/elasticsearch.list

RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends elasticsearch=$ELASTICSEARCH_VERSION \
	&& rm -rf /var/lib/apt/lists/*

ENV PATH /usr/share/elasticsearch/bin:$PATH

WORKDIR /usr/share/elasticsearch

RUN set -ex \
	&& for path in \
		./data \
		./logs \
		./config \
		./config/scripts \
	         /var/log/elasticsearch \
                 /var/data/elasticsearch \
	; do \
		mkdir -p "$path"; \
		chown -R elasticsearch:elasticsearch "$path"; \
	done

COPY config ./config

VOLUME /usr/share/elasticsearch/data

COPY docker-entrypoint.sh /

###############################################################################
#                                   Add Plugins
###############################################################################
ENV ES_HOME /usr/share/elasticsearch
WORKDIR ${ES_HOME}
RUN gosu elasticsearch bin/plugin install royrusso/elasticsearch-HQ
RUN gosu elasticsearch bin/plugin install cloud-azure
RUN gosu elasticsearch bin/plugin install lmenezes/elasticsearch-kopf
RUN gosu elasticsearch bin/plugin install -b com.floragunn/search-guard-ssl/2.3.3.13
RUN gosu elasticsearch bin/plugin install -b com.floragunn/search-guard-2/2.3.3.1

#add search-guard-ssl openssl dependencies
RUN gosu root wget http://repo1.maven.org/maven2/io/netty/netty-tcnative/1.1.33.Fork17/netty-tcnative-1.1.33.Fork17-linux-x86_64.jar
RUN gosu root mv netty-tcnative-1.1.33.Fork17-linux-x86_64.jar plugins/search-guard-ssl/
RUN gosu root wget http://ftp.de.debian.org/debian/pool/main/a/apr/libapr1_1.5.2-4_amd64.deb
RUN gosu root wget http://ftp.de.debian.org/debian/pool/main/o/openssl/libssl1.0.2_1.0.2h-1_amd64.deb
RUN gosu root wget http://ftp.de.debian.org/debian/pool/main/o/openssl/openssl_1.0.2h-1_amd64.deb
RUN gosu root dpkg -i *.deb && rm *.deb
###############################################################################

EXPOSE 9200 9300
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["elasticsearch"]
