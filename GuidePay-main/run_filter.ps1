$ErrorActionPreference = "Stop"

Write-Host "Committing safe changes..."
git add .
git commit -m "security: remove exposed credentials, fix gitignore, add safe env examples"

Write-Host "Installing git-filter-repo..."
pip install git-filter-repo

Write-Host "Filtering repository to remove secrets..."
git filter-repo --path backend/.env --invert-paths --force
git filter-repo --path frontend/.env --invert-paths --force
git filter-repo --path APIS_NEEDED.md --invert-paths --force

Write-Host "Re-adding remote..."
git remote add origin https://github.com/karthikeyavelivela/GuidePay.git

Write-Host "Force pushing changes..."
# We use Try/Catch to avoid crashing the script if there's no changes to push or minor issue
try {
    git push origin main --force
} catch {
    Write-Host "Push failed, you may need to manually push."
}

Write-Host "Done!"
