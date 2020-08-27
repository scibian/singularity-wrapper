#!/usr/bin/make -f
# -*- makefile -*-

%:
	dh $@

override_dh_install:
	dh_install
	{% if embed_image %}
	singularity-wrapper -d --embed-image --conf {{conf_file}} --images-build-root debian/{{package_name}} image-build {{ main_name }} > /var/log/{{ package_name }}_build_image.log 2>&1
	{% endif %}
