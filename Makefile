# Directories
FLOODING_DIR = /home/vagrant/mini-ndn/flooding
RESULTS_DIR = results
CONSUMER_LOG_DIR = /tmp/minindn/consumer/log
PRODUCER_LOG_DIR = /tmp/minindn/producer/log

# Log files
CONSUMER_INFO_LOG = $(RESULTS_DIR)/consumer_nfd_info.log \
                    $(RESULTS_DIR)/consumer_nlsr_info.log
PRODUCER_INFO_LOG = $(RESULTS_DIR)/producer_nfd_info.log \
                    $(RESULTS_DIR)/producer_nlsr_info.log

CONSUMER_DEBUG_LOG = $(RESULTS_DIR)/consumer_nfd_debug.log \
                     $(RESULTS_DIR)/consumer_nlsr_debug.log
PRODUCER_DEBUG_LOG = $(RESULTS_DIR)/producer_nfd_debug.log \
                     $(RESULTS_DIR)/producer_nlsr_debug.log

LOGS_INFO = $(CONSUMER_INFO_LOG) $(PRODUCER_INFO_LOG)
LOGS_DEBUG = $(CONSUMER_DEBUG_LOG) $(PRODUCER_DEBUG_LOG)

# Targets
all: start-vagrant $(LOGS_INFO) $(LOGS_DEBUG) stop-vagrant destroy-vagrant

start-vagrant:
	vagrant up --provider virtualbox

$(LOGS_INFO): | $(RESULTS_DIR)
	vagrant ssh -c 'cd $(FLOODING_DIR) && sudo python test1.py'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nfd.log /vagrant/$(RESULTS_DIR)/consumer_nfd_info.log'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nlsr.log /vagrant/$(RESULTS_DIR)/consumer_nlsr_info.log'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nfd.log /vagrant/$(RESULTS_DIR)/producer_nfd_info.log'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nlsr.log /vagrant/$(RESULTS_DIR)/producer_nlsr_info.log'

$(LOGS_DEBUG): | $(RESULTS_DIR)
	vagrant ssh -c 'cd $(FLOODING_DIR) && sudo python test2.py'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nfd.log /vagrant/$(RESULTS_DIR)/consumer_nfd_debug.log'
	vagrant ssh -c 'cp $(CONSUMER_LOG_DIR)/nlsr.log /vagrant/$(RESULTS_DIR)/consumer_nlsr_debug.log'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nfd.log /vagrant/$(RESULTS_DIR)/producer_nfd_debug.log'
	vagrant ssh -c 'cp $(PRODUCER_LOG_DIR)/nlsr.log /vagrant/$(RESULTS_DIR)/producer_nlsr_debug.log'

$(RESULTS_DIR):
	mkdir -p $(RESULTS_DIR)

stop-vagrant:
	vagrant halt

destroy-vagrant: stop-vagrant
	vagrant destroy -f

clean:
	rm -f $(LOGS_INFO) $(LOGS_DEBUG)

.PHONY: all start-vagrant stop-vagrant destroy-vagrant clean

.DELETE_ON_ERROR:
.NOTINTERMEDIATE:
MAKEFLAGS += --output-sync --warn-undefined-variables --no-builtin-rules --no-builtin-variables
