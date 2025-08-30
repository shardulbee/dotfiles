function create-repo --description 'Create a new repository with jj and GitHub'
    if test (count $argv) -ne 1
        echo "Usage: create-repo <repo-name>"
        return 1
    end

    set -l repo_name $argv[1]
    set -l repo_path "$HOME/Documents/$repo_name"

    # Check if directory already exists
    if test -d $repo_path
        echo "Error: Directory $repo_path already exists"
        return 1
    end

    echo "Creating new repository: $repo_name"

    # Create directory
    mkdir -p $repo_path
    or begin
        echo "Failed to create directory"
        return 1
    end

    cd $repo_path
    or begin
        echo "Failed to change to directory"
        return 1
    end

    # Initialize jj repository with git colocated
    echo "Initializing jj repository..."
    jj git init --colocate
    or begin
        echo "Failed to initialize jj repository"
        return 1
    end

    # Create GitHub repository
    echo "Creating GitHub repository..."
    gh repo create --private -s . $repo_name
    or begin
        echo "Failed to create GitHub repository"
        return 1
    end

    # Create README file
    echo "# $repo_name" >README.md

    # Create main bookmark
    echo "Setting up main bookmark..."
    jj bookmark create main
    or begin
        echo "Failed to create main bookmark"
        return 1
    end

    # Commit the changes
    echo "Committing initial changes..."
    jj commit -m "first commit"
    or begin
        echo "Failed to commit"
        return 1
    end

    # Push to GitHub with --allow-new flag for new bookmark
    echo "Pushing to GitHub..."
    jj git push --bookmark main --allow-new
    or begin
        echo "Failed to push to GitHub"
        return 1
    end

    set -l github_user (gh config get -h github.com user)
    echo "✓ Repository $repo_name created successfully!"
    echo "  Location: $repo_path"
    echo "  GitHub: https://github.com/$github_user/$repo_name"
end
