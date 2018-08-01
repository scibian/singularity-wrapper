#!/bin/bash
# Copyright (C) 2017 EDF SA
# Contact:
#       CCN - HPC <dsp-cspit-ccn-hpc@edf.fr>
#       1, Avenue du General de Gaulle
#       92140 Clamart
#
# Authors: CCN - HPC <dsp-cspit-ccn-hpc@edf.fr>
#
# This file is part of singularity-wrapper.
#
# singularity-wrapper is free software: you can redistribute in and/or
# modify it under the terms of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with puppet-hpc. If not, see
# <http://www.gnu.org/licenses/>.
IMAGE_PATH={{ image_path }}
EXE_PATH={{ exe_path }}

if [ ! -f "${IMAGE_PATH}" ] && [ ! -d "${IMAGE_PATH}" ]
then
  echo "singularity-wrapper: ERROR: Could not find singularity image '${IMAGE_PATH}'. It should have been built by your system administrator." >&2
  exit 1
fi

declare -a singularity_params
declare -a base_command

# Bind nvidia libraries if it used in the current session
opengl_vendor=$( (LANG=C glxinfo | sed -n "s/^OpenGL vendor string: \(.*\)/\1/;T;p") 2> /dev/null)
if [[ "${opengl_vendor}" == "NVIDIA Corporation" ]]
then
  singularity_params+=( '--nv' )
fi

base_command=( "${EXE_PATH}" )

# If the command is launched in a virtualgl context, relaunch it
# with vglrun inside the container if possible
if [[ "x${VGL_ISACTIVE}" == "x1" ]]
then
  if singularity exec "${singularity_params[@]}" "${IMAGE_PATH}" which vglrun >/dev/null 2>&1
  then
    base_command=( "vglrun" "${base_command[@]}" )
  else
    echo "singularity-wrapper: vglrun is not available inside the container ${IMAGE_PATH}." >&2
  fi
fi

exec singularity exec "${singularity_params[@]}" "${IMAGE_PATH}" "${base_command[@]}" "${@}"
