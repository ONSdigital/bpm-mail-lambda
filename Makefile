install:
	# quit if envar not set for STAGE (TF_VAR_stage)
	ifndef STAGE
	$(error STAGE is not set)
	endif
	# Freshen the zip
	(cd lambdas; zip -g9 ../function.zip lambda_function.py)
	terraform workspace select $(STAGE) terraform/ || terraform workspace new $(STAGE) terraform/
	TF_VAR_stage="$(STAGE)" TF_VAR_configuration="$(CONFIGURATION)" TF_VAR_BPM_USER="$(BPM_USER)" TF_VAR_BPM_PW="$(BPM_PW)" terraform apply terraform/

test:
	pipenv run pytest ./tests
