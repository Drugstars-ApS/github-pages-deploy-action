#!/bin/sh -l

if [ -z "$ACCESS_TOKEN" ]
then
  echo "You must provide the action with a GitHub Personal Access Token secret in order to deploy."
  exit 1
fi

if [ -z "$BRANCH" ]
then
  echo "You must provide the action with a branch name it should deploy to, for example gh-pages or docs."
  exit 1
fi

if [ -z "$FOLDER" ]
then
  echo "You must provide the action with the folder name in the repository where your compiled page lives."
  exit 1
fi

if [ -z "$COMMIT_EMAIL" ]
then
  COMMIT_EMAIL="${GITHUB_ACTOR}@users.noreply.github.com"
fi

if [ -z "$COMMIT_NAME" ]
then
  COMMIT_NAME="${GITHUB_ACTOR}"
fi

# Installs Git.
apt-get update && \
apt-get install -y git && \

# Directs the action to the the Github workspace.
cd $GITHUB_WORKSPACE && \

# Configures Git.
git init && \
git config --global user.email "${COMMIT_EMAIL}" && \
git config --global user.name "${COMMIT_NAME}" && \

## Checks to see if the remote exists prior to deploying
REMOTE_BRANCH = `git ls-remote --heads "https://${ACCESS_TOKEN}@github.com:JamesIves/reddit-viewer.git" docs`

# If the branch doesn't exist it gets created here as an orphan.
if [[ -z $REMOTE_BRANCH ]] 
then
  git checkout --orphan $BRANCH && \
  git rm -rf . && \
  touch README.md && \
  git add README.md && \
  git commit -m "Initial ${BRANCH} commit" && \
  git push origin $BRANCH
fi

# Checks out the base branch to begin the deploy process.
git checkout "${BASE_BRANCH:-master}" && \

## Initializes the repository path using the access token.
REPOSITORY_PATH="https://${ACCESS_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" && \


# Builds the project if a build script is provided.
echo "Running build scripts... $BUILD_SCRIPT"
eval "$BUILD_SCRIPT"

# Commits the data to Github.
echo "Deploying to GitHub..." && \
git add -f $FOLDER && \
git commit -m "Deploying to ${BRANCH} - $(date +"%T")" && \
git push $REPOSITORY_PATH `git subtree split --prefix $FOLDER master`:$BRANCH --force && \
echo "Deployment Succesful!"