### Add functions here and link them to builder-bit format MUST BE "build-FunctionResourceName in template.yaml"

build-SELambda: builder-bot

######################  No Change required below this line  ##########################

file := id_rsa 
#SSH_KEY := $(shell cat ${file}) #Use this to get value from shell command. This expands newlines to white spaces which doens't work for ssh keys.

builder-bot:
	$(eval $@PRODUCT = $(subst build-,,$(MAKECMDGOALS)))
	$(eval $@BUILD_DIR = $(PWD)/.aws-sam/build-$($@PRODUCT))
	$(eval $@STAGE = $($@BUILD_DIR)/lambda)
	$(eval $@ARTIFACTS_DIR = $(PWD)/.aws-sam/build/$($@PRODUCT))
	
	# Create docker file
	#docker build -f Dockerfile . -t builder --build-arg SSH_PRIVATE_KEY="$(SSH_KEY)"
	docker build --platform linux/arm64 -f Dockerfile-Makefile . -t builder

	# Prep directories
	mkdir -p $($@BUILD_DIR)/lambda $($@ARTIFACTS_DIR)

	# Compile application
	DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker run --platform linux/arm64 --rm -v $($@BUILD_DIR):/build-target -v `pwd`:/build-src -w /build-src builder bash -c "swift package resolve -v; swift build --product $($@PRODUCT) -c release --build-path /build-target"

	# Copy dependencies
	docker run --platform linux/arm64 --rm -v $($@BUILD_DIR):/build-target -v `pwd`:/build-src -w /build-src builder bash -cl "ldd '/build-target/release/$($@PRODUCT)' | grep swift | cut -d ' ' -f 3 | xargs -I{} cp -Lv {} /build-target/lambda"
	
	# Copy binary to stage
	cp $($@BUILD_DIR)/release/$($@PRODUCT) $($@BUILD_DIR)/lambda/bootstrap
	
	# Copy app from stage to artifacts dir
	sudo cp $($@STAGE)/* $($@ARTIFACTS_DIR)
