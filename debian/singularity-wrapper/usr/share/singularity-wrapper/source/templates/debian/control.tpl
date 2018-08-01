Source: {{ package_name }}
Priority: optional
Maintainer: {{ package_maintainer }}
Build-Depends:
 debhelper (>= 9)
Standards-Version: 3.9.6
Section: admin

Package: {{ package_name }}
Architecture: all
Depends:
 ${shlibs:Depends},
 ${misc:Depends},
 singularity-wrapper
Description: Wrapper package around a singularity image for {{ package_orig_name }}
 This package provides wrapper script for the package executables as well as
 manpages, icons, desktop files...
 It also add description necessary to build the singularity image locally.
