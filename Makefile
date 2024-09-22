# Vagrantfile path
VAGRANTFILE = Vagrantfile
RESULTS_DIR = results
FLOODING_DIR = /home/vagrant/mini-ndn/flooding
CONSUMER_LOG_DIR = /tmp/minindn/consumer/log
PRODUCER_LOG_DIR = /tmp/minindn/producer/log

# Vagrant VM start
start-vagrant:
	vagrant up --provider virtualbox

# Compile consumer.cpp
compile-consumer: start-vagrant
	vagrant ssh -c 'cd $(FLOODING_DIR) && \
	g++ -std=c++17 -o consumer consumer.cpp $$(pkg-config --cflags --libs libndn-cxx)'

# Compile producer.cpp
compile-producer: start-vagrant
	vagrant ssh -c 'cd $(FLOODING_DIR) && \
	g++ -std=c++17 -o producer producer.cpp $$(pkg-config --cflags --libs libndn-cxx)'

# Generate trust anchor
generate-keys: start-vagrant
	vagrant ssh -c 'cd $(FLOODING_DIR) && \
	ndnsec key-gen /example && \
	ndnsec cert-dump -i /example > example-trust-anchor.cert && \
	ndnsec key-gen /example/testApp && \
	ndnsec sign-req /example/testApp | ndnsec cert-gen -s /example -i example | ndnsec cert-install -'

# Run the first experiment (test1.py) and collect logs
run-test1: compile-consumer compile-producer generate-keys
	vagrant ssh -c 'cd $(FLOODING_DIR) && sudo python test1.py'
	mkdir -p $(RESULTS_DIR)
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nfd.log /vagrant/$(RESULTS_DIR)/consumer_nfd_info.log'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nlsr.log /vagrant/$(RESULTS_DIR)/consumer_nlsr_info.log'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nfd.log /vagrant/$(RESULTS_DIR)/producer_nfd_info.log'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nlsr.log /vagrant/$(RESULTS_DIR)/producer_nlsr_info.log'

# Run the second experiment (test2.py) and collect logs
run-test2: run-test1
	vagrant ssh -c 'cd $(FLOODING_DIR) && sudo python test2.py'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nfd.log /vagrant/$(RESULTS_DIR)/consumer_nfd_debug.log'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nlsr.log /vagrant/$(RESULTS_DIR)/consumer_nlsr_debug.log'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nfd.log /vagrant/$(RESULTS_DIR)/producer_nfd_debug.log'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nlsr.log /vagrant/$(RESULTS_DIR)/producer_nlsr_debug.log'

# Shut down Vagrant VM
stop-vagrant: run-test2
	vagrant halt

# Clean Vagrant VM
clean-vagrant: stop-vagrant
	vagrant destroy -f

# Run all steps, generate results, and export them
all: clean-vagrant
