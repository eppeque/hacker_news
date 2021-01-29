# Contributing to the Hacker News reader app

I invite you to join me! Everyone is welcome to contribute code via pull requests, to file issues on Github, to add something in our documentation, or to help out in any other way.

I grant commit access to people who have gained my trust and demonstrated a commitment to this app.

## File issues

You can file issues on Github to highlight the presence of bugs, to submit your ideas for new features or simply ask a question about the code.

## Pull requests

You can obviously skip the step of proposing a feature to develop it right away! You'll need to do pull requests if you want directly change the source code. Here are the steps to follow:

* Fork the repo
* Clone the repo on your computer
* Add the remote "upstream" with this command: `git remote add upstream https://github.com/eppeque/hacker_news.git`
* Fetch the data of the remote with this command: `git fetch upstream`
* Set up the master branch so that when you run the `git pull` command, you download the code directly from this repo and not from your forked one. You can do this with this command: `git branch --set-upstream-to=upstream/main main`
* Create a branch for your edits
* Set up your new branch so that when you run the `git push` command, you upload the code on your forked repo. You can do this with this command: `git push --set-upstream origin <THE NAME OF THE BRANCH WITH YOUR EDITS>`
* Make your changes
* Commit your changes
* Push your changes
* You are now able to submit a pull request on Github by selecting the branch with your edits

Thank you in advance for your interest and happy coding!
