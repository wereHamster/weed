#!/bin/sh

# Load the local config file.
test -f ./config && . ./config

# Clone the git repo into $TMPDIR. Use http because users may be behind
# firefalls or proxies. Unfortunately some proxies corrupt the smart-http
# stream so use kernel.org which still uses dumb http.
GIT_TMP_DIR="${TMPDIR-/tmp}/weed-git-$USER"
if ! test -d "$GIT_TMP_DIR"; then
  git clone http://www.kernel.org/pub/scm/git/git.git "$GIT_TMP_DIR"
fi

# Change into the git directory and update the repo.
cd "$GIT_TMP_DIR"
git remote update >/dev/null

# The branches we build and the compilers we use.
BRANCHES="maint master next pu"
COMPILER="$(gcc -dumpmachine)-gcc-$(gcc -dumpversion) $COMPILER"

# Git requires gmake, assume make is gmake but allow the user
# to override it.
MAKE="${MAKE-make}"

# And now do the real work.
for branch in $BRANCHES; do
  if test "x$(git rev-parse --quiet --verify $branch)" != "x$(git rev-parse origin/$branch)"; then
    for compiler in $COMPILER; do
      echo " *** Smoking $branch using $compiler ***"
      SMOKE_TAGS="$branch,$compiler" && export SMOKE_TAGS

      git clean -dfx &&
      git checkout $branch &&
      git reset --hard origin/$branch &&
      ${MAKE} all CC=$compiler $OPTS &&
      cd t &&
      ${MAKE} smoke_report
    done
  fi
done
