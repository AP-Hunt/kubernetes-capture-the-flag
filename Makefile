SOPS_AGE_KEY_FILE ?= ~/.config/sops/age/keys.txt
SOPS := SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) sops

SECRET_FILES := $(shell find . -name '*secret*\.yaml' -not -path './.git/*')

.PHONY: encrypt decrypt encrypt-file decrypt-file

## Encrypt all secret files in-place
encrypt:
	@for f in $(SECRET_FILES); do \
		echo "Encrypting $$f"; \
		$(SOPS) encrypt --in-place "$$f"; \
	done

## Decrypt all secret files in-place
decrypt:
	@for f in $(SECRET_FILES); do \
		echo "Decrypting $$f"; \
		$(SOPS) decrypt --in-place "$$f"; \
	done

## Encrypt a single file: make encrypt-file FILE=path/to/secret.yaml
encrypt-file:
	$(SOPS) encrypt --in-place "$(FILE)"

## Decrypt a single file: make decrypt-file FILE=path/to/secret.yaml
decrypt-file:
	$(SOPS) decrypt --in-place "$(FILE)"
