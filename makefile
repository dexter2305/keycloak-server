VERBOSE ?= 0
.REDIRECT = $(if $(filter 1,$(VERBOSE)),,>/dev/null 2>&1)


.NAME = keycloak
.POD = $(.NAME)-pod
.KC_VERSION = 26.1.2
.KC_CNTR_NAME = $(.NAME)
.KC_HOST = 127.0.0.1
.KC_PORT = 8443

.PHONY: keycloak-start
keycloak-start: generate-certs ## starts keycloak as container
	podman pod create --name $(.POD) --replace --publish $(.KC_HOST):$(.KC_PORT):8443 $(.REDIRECT)
	podman run --pod $(.POD) --replace --detach \
		--name $(.KC_CNTR_NAME) \
		--env KC_BOOTSTRAP_ADMIN_USERNAME=admin \
		--env KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
		--env KEYCLOAK_LOGLEVEL=DEBUG \
		--env KC_HTTPS_CERTIFICATE_FILE=/etc/keycloak/keycloak.crt \
		--env KC_HTTPS_CERTIFICATE_KEY_FILE=/etc/keycloak/keycloak.key \
		--volume $$(pwd)/keycloak.crt:/etc/keycloak/keycloak.crt:Z \
		--volume $$(pwd)/keycloak.key:/etc/keycloak/keycloak.key:Z \
		--volume keycloak-data:/opt/keycloak/data \
		quay.io/keycloak/keycloak:$(.KC_VERSION) start-dev $(.REDIRECT)
	printf "%-20s %s\n" "keycloak" "Serving at 'https://$(.KC_HOST):$(.KC_PORT)/admin'"

.PHONY: clean
clean: ## stop keycloak
	podman pod rm -f $(.POD) $(.REDIRECT) && \
	rm keycloak.key keycloak.crt $(.REDIRECT) || \ 
	printf "%-20s %s\n" "keycloak" "Certs removed. Server stopped."

.PHONY: generate-certs
generate-certs: ## generates self signed certificate
	openssl req -x509 -newkey rsa:4096 \
		-keyout keycloak.key -out keycloak.crt \
		-days 365 -nodes -subj "/CN=localhost" $(.REDIRECT) && \
		printf "%-20s %s\n" "certs" "Created" && \
		chmod 644 keycloak.key || \
		printf "%-20s %s\n" "certs" "Failed to create"
