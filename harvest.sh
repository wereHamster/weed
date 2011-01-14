#!/bin/sh

# Load the smoke credentials and local config if present.
test -f ./credentials && . ./credentials
test -f ./config      && . ./config

# Clone the git repo into $TMPDIR. Use http because users may be behind
# firefalls or proxies, and use github because kernel.org doesn't support
# smart http.
GIT_TMP_DIR="${TMPDIR-/tmp}/weed-git-$USER"
if ! test -d "$GIT_TMP_DIR"; then
  git clone https://github.com/git/git.git "$GIT_TMP_DIR"
fi

# Change into the git directory and update the repo.
cd "$GIT_TMP_DIR"
git remote update >/dev/null

# The branches we build and the compilers we use.
BRANCHES="maint master next pu"
COMPILER="$(gcc -dumpmachine)-gcc-$(gcc -dumpversion) $COMPILER"

# And now do the real work.
for branch in $BRANCHES; do
  if test "x$(git rev-parse --quiet --verify $branch)" != "x$(git rev-parse origin/$branch)"; then
    for compiler in $COMPILER; do
      export SMOKE_TAGS="$branch,$compiler"
      echo " *** Smoking $branch using $compiler ***"

      git clean -dfx &&
        git checkout $branch &&
        git reset --hard origin/$branch &&
        make clean all CC=$compiler &&
        cd t &&
        make smoke_report
    done
  fi
done
