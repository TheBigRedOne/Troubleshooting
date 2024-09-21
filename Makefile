# Paths
VAGRANTFILE = Vagrantfile
FLOODING_DIR = /home/vagrant/mini-ndn/flooding
RESULTS_DIR = results
CONSUMER_LOG_DIR = /tmp/minindn/consumer/log
PRODUCER_LOG_DIR = /tmp/minindn/producer/log

# Executable names
CONSUMER_EXEC = consumer
PRODUCER_EXEC = producer

# Logs and output files
CONSUMER_LOG_INFO = $(RESULTS_DIR)/consumer_nfd_info.log
PRODUCER_LOG_INFO = $(RESULTS_DIR)/producer_nfd_info.log
CONSUMER_NLSR_INFO = $(RESULTS_DIR)/consumer_nlsr_info.log
PRODUCER_NLSR_INFO = $(RESULTS_DIR)/producer_nlsr_info.log

CONSUMER_LOG_DEBUG = $(RESULTS_DIR)/consumer_nfd_debug.log
PRODUCER_LOG_DEBUG = $(RESULTS_DIR)/producer_nfd_debug.log
CONSUMER_NLSR_DEBUG = $(RESULTS_DIR)/consumer_nlsr_debug.log
PRODUCER_NLSR_DEBUG = $(RESULTS_DIR)/producer_nlsr_debug.log

# Markers for completed experiments
TEST1_DONE = $(RESULTS_DIR)/test1_done
TEST2_DONE = $(RESULTS_DIR)/test2_done

# Ensure the results directory exists
create-results-dir:
	mkdir -p $(RESULTS_DIR)

# Main targets
all: $(CONSUMER_LOG_INFO) $(PRODUCER_LOG_INFO) $(CONSUMER_NLSR_INFO) $(PRODUCER_NLSR_INFO) \
     $(CONSUMER_LOG_DEBUG) $(PRODUCER_LOG_DEBUG) $(CONSUMER_NLSR_DEBUG) $(PRODUCER_NLSR_DEBUG)

$(CONSUMER_EXEC): | start-vagrant
	vagrant ssh -c 'cd $(FLOODING_DIR) && g++ -std=c++17 -o $(CONSUMER_EXEC) consumer.cpp $$(pkg-config --cflags --libs libndn-cxx)'

$(PRODUCER_EXEC): | start-vagrant
	vagrant ssh -c 'cd $(FLOODING_DIR) && g++ -std=c++17 -o $(PRODUCER_EXEC) producer.cpp $$(pkg-config --cflags --libs libndn-cxx)'

# Experiment 1: Run test1.py and gather logs
$(TEST1_DONE): $(CONSUMER_EXEC) $(PRODUCER_EXEC) generate-keys create-results-dir | start-vagrant
	vagrant ssh -c 'cd $(FLOODING_DIR) && sudo python test1.py'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nfd.log /vagrant/$(CONSUMER_LOG_INFO)'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nlsr.log /vagrant/$(CONSUMER_NLSR_INFO)'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nfd.log /vagrant/$(PRODUCER_LOG_INFO)'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nlsr.log /vagrant/$(PRODUCER_NLSR_INFO)'
	touch $(TEST1_DONE)

# Experiment 2: Run test2.py and gather logs
$(TEST2_DONE): $(TEST1_DONE) create-results-dir | start-vagrant
	vagrant ssh -c 'cd $(FLOODING_DIR) && sudo python test2.py'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nfd.log /vagrant/$(CONSUMER_LOG_DEBUG)'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nlsr.log /vagrant/$(CONSUMER_NLSR_DEBUG)'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nfd.log /vagrant/$(PRODUCER_LOG_DEBUG)'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nlsr.log /vagrant/$(PRODUCER_NLSR_DEBUG)'
	touch $(TEST2_DONE)

# Vagrant management
start-vagrant:
	vagrant up --provider virtualbox

stop-vagrant:
	vagrant halt

clean-vagrant:
	vagrant destroy -f

# Key generation
generate-keys: | start-vagrant
	vagrant ssh -c 'cd $(FLOODING_DIR) && \
	ndnsec key-gen /example && \
	ndnsec cert-dump -i /example > example-trust-anchor.cert && \
	ndnsec key-gen /example/testApp && \
	ndnsec sign-req /example/testApp | ndnsec cert-gen -s /example -i example | ndnsec cert-install -'

# Cleanup: Only remove the compiled executables, but preserve logs
clean:
	vagrant ssh -c 'cd $(FLOODING_DIR) && rm -f $(CONSUMER_EXEC) $(PRODUCER_EXEC)'
	rm -f $(TEST1_DONE) $(TEST2_DONE)

# .PHONY ensures these are not treated as files
.PHONY: all start-vagrant stop-vagrant clean-vagrant generate-keys clean create-results-dir

# Automatically remove files on error
.DELETE_ON_ERROR:

