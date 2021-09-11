# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursive variables
SHELL = /usr/bin/sh
PROJECT_CONFIG_FILE_NAME = .conf

# targets
HELP = help
CONFIGS = configs
CLEAN = clean

# executables
ENVSUBST = envsubst

# default var values
MAX_ROOT_PARTITION_SIZE_DEFAULT = -1  \# indicates unlimited partition size
DISK_DEFAULT = "/dev/sda"  \# e.g. /dev/sda, not /dev/discs/disc0/disc

# should list all the vars in the multiline var below
NORMAL_USER_NAME = $${NORMAL_USER_NAME}
NORMAL_USER_PASSWORD = $${NORMAL_USER_PASSWORD}
NORMAL_USER_FULL_NAME = $${NORMAL_USER_FULL_NAME}
MAX_SWAP_PARTITION_SIZE = $${MAX_SWAP_PARTITION_SIZE}
MAX_ROOT_PARTITION_SIZE = $${MAX_ROOT_PARTITION_SIZE}
LUKS_PASSPHRASE = $${LUKS_PASSPHRASE}
GITHUB_API_TOKEN = $${GITHUB_API_TOKEN}
DISK = $${DISK}
project_config_file_vars = \
	${NORMAL_USER_NAME}\
	${NORMAL_USER_PASSWORD}\
	${NORMAL_USER_FULL_NAME}\
	${MAX_SWAP_PARTITION_SIZE}\
	${MAX_ROOT_PARTITION_SIZE}\
	${LUKS_PASSPHRASE}\
	${GITHUB_API_TOKEN}\
	${DISK}

define PROJECT_CONFIG_FILE =
cat << _EOF_
#
#
# Config file to centralize vars, and to aggregate common vars.

# needed to construct gerald_debian_preseed.cfg
export NORMAL_USER_NAME=
export NORMAL_USER_PASSWORD=
export NORMAL_USER_FULL_NAME=
# partition sizes are in bytes
export MAX_SWAP_PARTITION_SIZE=
export MAX_ROOT_PARTITION_SIZE=${MAX_ROOT_PARTITION_SIZE_DEFAULT}
export LUKS_PASSPHRASE=
export GITHUB_API_TOKEN=
export DISK=${DISK_DEFAULT}
_EOF_
endef
# Use the $(value ...) function if there are other variables in the multi-line
# variable that should be evaluated by the shell and not make! e.g. 
# export PROJECT_CONFIG_FILE = $(value _PROJECT_CONFIG_FILE)
export PROJECT_CONFIG_FILE

# simply expanded variables
CONFIG_EXT := .cfg
config_wildcard := %${CONFIG_EXT}
SHELL_TEMPLATE_EXT := .shtpl
shell_template_wildcard := %${SHELL_TEMPLATE_EXT}
config_shell_template_ext := ${CONFIG_EXT}${SHELL_TEMPLATE_EXT}
config_shell_template_wildcard := %${CONFIG_EXT}${SHELL_TEMPLATE_EXT}
config_shell_templates := $(shell find ${CURDIR} -name *${config_shell_template_ext})

# Determines the config name(s) to be generated from the template(s).
# Short hand notation for string substitution: $(text:pattern=replacement).
configs := $(config_shell_templates:${config_shell_template_wildcard}=${config_wildcard})

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Available make targets:'
>	@echo '  ${PROJECT_CONFIG_FILE_NAME}            - generates the configuration file to be used by other'
>	@echo '                     make targets. Particularly targets that utilize shell'
>	@echo '                     templates.'
>	@echo '  ${CONFIGS}          - generates the configuration files to be used'
>	@echo '  ${CLEAN}            - removes files generated from other targets'

${PROJECT_CONFIG_FILE_NAME}:
>	eval "$${PROJECT_CONFIG_FILE}" > "${CURDIR}/${PROJECT_CONFIG_FILE_NAME}"

.PHONY: ${CONFIGS}
${CONFIGS}: ${configs}

# custom implicit rules for the above targets
${config_wildcard}: ${config_shell_template_wildcard} ${PROJECT_CONFIG_FILE_NAME}
>	@[ -f "${CURDIR}/${PROJECT_CONFIG_FILE_NAME}" ] || { echo "${PROJECT_CONFIG_FILE_NAME} must be generated, run 'make ${PROJECT_CONFIG_FILE_NAME}'"; exit 1; }
>	. "${CURDIR}/${PROJECT_CONFIG_FILE_NAME}" && ${ENVSUBST} '${project_config_file_vars}' < "$<" > "$@"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force ${configs}
