# newproject: create ~/repos/<name> as a uv project with a public GitHub repo,
# main/test/dev branches, and a GitHub Pages site (via `git ship init`).
# A shell function (not a script) so it can leave you cd'ed into the new project.
#
# Loaded by zsh via a symlink: ~/.oh-my-zsh/custom/newproject.zsh -> this file
# Needs: uv, gh (logged in), and dev-tools/bin on PATH (for git ship).
newproject () {
	local proj_name="$1" repos_dir="$HOME/repos" owner choice
	# Letters, digits, . _ - (what GitHub, mkdir and cd all accept); no leading dot
	local valid_name='^[A-Za-z0-9_-][A-Za-z0-9._-]{0,99}$'

	# --- Checks: nothing is created until all of these pass ---
	if [[ -z "$proj_name" ]]; then
		echo "Usage: newproject <name>"
		return 1
	fi
	if [[ ! "$proj_name" =~ $valid_name ]]; then
		echo "Error: '$proj_name' isn't a valid name. Use letters, digits, '.', '_' and '-' (not starting with '.')."
		return 1
	fi
	if [[ -e "$repos_dir/$proj_name" ]]; then
		echo "Error: $repos_dir/$proj_name already exists."
		return 1
	fi
	if ! command -v uv > /dev/null; then
		echo "Error: uv isn't installed (brew install uv)."
		return 1
	fi
	if ! command -v gh > /dev/null; then
		echo "Error: gh isn't installed (brew install gh)."
		return 1
	fi
	if ! gh auth status > /dev/null 2>&1; then
		echo "Error: gh isn't logged in (run: gh auth login)."
		return 1
	fi
	if ! command -v git-ship > /dev/null; then
		echo "Error: git ship not found. Add ~/repos/dev-tools/bin to PATH in ~/.zshrc."
		return 1
	fi
	owner=$(gh api user -q .login) || return 1
	if gh repo view "$owner/$proj_name" > /dev/null 2>&1; then
		echo "Error: github.com/$owner/$proj_name already exists."
		return 1
	fi

	# --- Confirm ---
	while true; do
		read "choice?Create '$proj_name' in ${(D)repos_dir}/ and as public repo $owner/$proj_name? (y/n): "
		case "$choice" in
			([yY]) break ;;
			([nN]) echo "Operation cancelled."; return 0 ;;
			(*) echo "Please enter 'y' or 'n'." ;;
		esac
	done

	# --- Create (stops at the first failure) ---
	echo "Making folder '$proj_name' in $repos_dir/."
	cd "$repos_dir" && mkdir "$proj_name" && cd "$proj_name" || return 1

	echo "Initializing uv project."
	uv init || return 1
	uv add -q --group dev jupyter ipykernel || return 1
	git branch -M main || return 1

	echo "# $proj_name" >> README.md
	# Where `git ship` publishes the frontend from (see dev-tools README)
	echo "FRONTEND_DIR=website" > .ship

	# Ignored in every project, added to uv's .gitignore unless already there:
	# macOS folder metadata, virtual environments at any depth, and the contents of data/
	local pattern
	[[ -s .gitignore && -n "$(tail -c 1 .gitignore)" ]] && echo >> .gitignore
	echo "\n# Project defaults (newproject)" >> .gitignore
	for pattern in ".DS_Store" ".venv/" "data/*"; do
		grep -qxF -- "$pattern" .gitignore || echo "$pattern" >> .gitignore
	done

	echo "Committing."
	# README, .ship and .gitignore; uv's other starter files stay uncommitted
	# so you can drop any you don't need
	git add README.md .ship .gitignore && git commit -q -m "repo setup" || return 1

	echo "Creating repo on GitHub."
	gh repo create "$owner/$proj_name" --public || return 1
	git remote add origin "git@github.com:$owner/$proj_name.git" || return 1

	echo "Pushing dev, test, and main."
	# test and dev start as copies of main; output is shown only if something fails
	local branch out
	git branch test main && git branch dev main || return 1
	for branch in dev test main; do
		out=$(git push -u origin "$branch" 2>&1) || { echo "$out"; echo "Error: pushing $branch failed."; return 1; }
	done
	git switch -q dev || return 1

	echo "Setting up GitHub Pages."
	git ship init || return 1

	echo -e "\nGood luck with $proj_name!\n"
}
