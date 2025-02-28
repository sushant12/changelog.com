CHANGELOG_DEPLOYMENT := app
CHANGELOG_NAMESPACE := prod-2020-07
CHANGELOG_TREE := $(KUBETREE) deployments $(CHANGELOG_DEPLOYMENT) --namespace $(CHANGELOG_NAMESPACE)
# Copy of https://changelog.com
# Enable debugging if make runs in debug mode
ifneq (,$(findstring d,$(MFLAGS)))
  WHO_IS_DEBUGGING ?= $(USER)
endif
.PHONY: lke-changelog
lke-changelog: | lke-ctx $(KUBETREE) $(YTT)
	$(YTT) \
	  --data-value app.name=$(CHANGELOG_DEPLOYMENT) \
	  --data-value namespace=$(CHANGELOG_NAMESPACE) \
	  --data-value debug=$(WHO_IS_DEBUGGING) \
	  --file $(CURDIR)/k8s/changelog > $(CURDIR)/k8s/changelog.yml \
	&& $(KUBECTL) apply --filename $(CURDIR)/k8s/changelog.yml \
	&& $(CHANGELOG_TREE)

.PHONY: lke-changelog-update
lke-changelog-update: | lke-ctx
	$(KUBECTL) rollout restart deployments/$(CHANGELOG_DEPLOYMENT) --namespace $(CHANGELOG_NAMESPACE) \
	&& $(KUBECTL) rollout status --watch deployments/$(CHANGELOG_DEPLOYMENT) --namespace $(CHANGELOG_NAMESPACE)

.PHONY: lke-changelog-sh
lke-changelog-sh: | lke-ctx
	$(KUBECTL) exec --stdin=true --tty=true --namespace $(CHANGELOG_NAMESPACE) \
	  deployments/$(CHANGELOG_DEPLOYMENT) -c app -- bash --login

.PHONY: lke-changelog-tree
lke-changelog-tree: | lke-ctx $(KUBETREE)
	$(CHANGELOG_TREE)

.PHONY: lke-changelog-db-shell
lke-changelog-db-shell: lke-changelog-db-restore

.PHONY: lke-changelog-db-restore
lke-changelog-db-restore: | lke-ctx
	$(KUBECTL) exec --stdin=true --tty=true --namespace $(CHANGELOG_NAMESPACE) \
	  deployments/$(CHANGELOG_DEPLOYMENT) -c db-backup -- bash --login

# ^^^ Within the db-restore container run:
#
# 	clean_db
# 	restore_db_from_backup

PGDATABASE ?= changelog_dev
export PGDATABASE
.PHONY: lke-changelog-db-restore-local
lke-changelog-db-restore-local: | $(AWS)
	cd docker \
	&& export PATH=$$(PWD):$$PATH \
	&& export AWS_ACCESS_KEY_ID=$(BACKUPS_AWS_ACCESS_KEY) \
	&& export AWS_SECRET_ACCESS_KEY=$(BACKUPS_AWS_SECRET_KEY) \
	&& export AWS_S3_BUCKET=changelog-com-backups \
	&& ./restore_db_from_backup

.PHONY: lke-changelog-db-backup
lke-changelog-db-backup: | lke-ctx
	$(KUBECTL) exec --stdin=true --tty=true --namespace $(CHANGELOG_NAMESPACE) \
	  deployments/$(CHANGELOG_DEPLOYMENT) -c db-backup -- backup_db_to_s3

.PHONY: lke-changelog-backups
lke-changelog-backups: | lke-ctx
	$(KUBECTL) exec --stdin=true --tty=true --namespace $(CHANGELOG_NAMESPACE) \
	  deployments/$(CHANGELOG_DEPLOYMENT) -c db-backup -- s3_backups

.PHONY: lke-changelog-uploads-backup
lke-changelog-uploads-backup: | lke-ctx
	$(KUBECTL) exec --stdin=true --tty=true --namespace $(CHANGELOG_NAMESPACE) \
	  deployments/$(CHANGELOG_DEPLOYMENT) -c uploads-backup -- backup_uploads_to_s3

.PHONY: lke-changelog-tls-sync-fastly
lke-changelog-tls-sync-fastly: | lke-ctx
	$(KUBECTL) create job --namespace $(CHANGELOG_NAMESPACE) \
	  --from=cronjob/tls-sync-fastly tls-sync-fastly-manual-$(USER)

.PHONY: lke-changelog-secrets
lke-changelog-secrets:: campaignmonitor-lke-secret
lke-changelog-secrets:: github-lke-secret
lke-changelog-secrets:: hackernews-lke-secret
lke-changelog-secrets:: aws-lke-secret
lke-changelog-secrets:: backups-aws-lke-secret
lke-changelog-secrets:: shopify-lke-secret
lke-changelog-secrets:: twitter-lke-secret
lke-changelog-secrets:: app-lke-secret
lke-changelog-secrets:: slack-lke-secret
lke-changelog-secrets:: rollbar-lke-secret
lke-changelog-secrets:: buffer-lke-secret
lke-changelog-secrets:: coveralls-lke-secret
lke-changelog-secrets:: algolia-lke-secret
lke-changelog-secrets:: plusplus-lke-secret
lke-changelog-secrets:: fastly-lke-secret
lke-changelog-secrets:: hcaptcha-lke-secret
lke-changelog-secrets:: grafana-lke-secret
lke-changelog-secrets:: promex-lke-secret
lke-changelog-secrets:: sentry-lke-secret

ARKADE_RELEASES := https://github.com/alexellis/arkade/releases
ARKADE_VERSION := 0.6.35
ARKADE_BIN := arkade-v$(ARKADE_VERSION)-$(platform)
ARKADE_URL := https://github.com/alexellis/arkade/releases/download/$(ARKADE_VERSION)/arkade-$(platform)
ARKADE := $(LOCAL_BIN)/$(ARKADE_BIN)
$(ARKADE): | $(CURL) $(LOCAL_BIN)
	$(CURL) --progress-bar --fail --location --output $(ARKADE) "$(ARKADE_URL)"
	touch $(ARKADE)
	chmod +x $(ARKADE)
	$(ARKADE) version | grep $(ARKADE_VERSION)
	ln -sf $(ARKADE) $(LOCAL_BIN)/arkade
.PHONY: arkade
arkade: $(ARKADE)
.PHONY: releases-arkade
releases-arkade:
	@$(OPEN) $(ARKADE_RELEASES)

# m openfaas-find-latest
OPENFAAS_VERSION ?= 7.0.2
OPENFAAS_NAMESPACE := openfaas
.PHONY: openfaas
openfaas: | lke-ctx $(HELM)
	$(HELM) repo add openfaas https://openfaas.github.io/faas-netes/
	$(HELM) upgrade openfaas openfaas/openfaas \
	  --install \
	  --version $(OPENFAAS_VERSION) \
	  --set functionNamespace=$(CHANGELOG_NAMESPACE) \
	  --set generateBasicAuth=true \
	  --create-namespace \
	  --namespace $(OPENFAAS_NAMESPACE)

openfaas-find-latest: | $(HELM)
	$(HELM) repo update
	$(HELM) search repo openfaas/openfaas
