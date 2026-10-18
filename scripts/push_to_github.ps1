#!/usr/bin/env pwsh
# push_to_github.ps1
# Chạy script này để push code lên GitHub
# Yêu cầu: GitHub Personal Access Token (PAT)
#
# Cách tạo PAT:
# 1. Vào https://github.com/settings/tokens
# 2. Click "Generate new token (classic)"
# 3. Tích chọn: repo (full control)
# 4. Copy token (chỉ hiển thị 1 lần)
# 5. Paste vào ô GITHUB_TOKEN bên dưới

param(
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$GitHubUsername = "pdthang125",
    [string]$RepoName = "Trekking"
)

if (-not $GitHubToken) {
    Write-Host "❌ Cần GITHUB_TOKEN. Chạy: `$env:GITHUB_TOKEN='your_token_here'"
    Write-Host "   Hoặc: .\push_to_github.ps1 -GitHubToken 'your_token'"
    exit 1
}

$env:PATH = "C:\Program Files\Git\cmd;" + $env:PATH

Set-Location "C:\Trekking\trekguard_ai"

# Set remote URL with token
$remoteUrl = "https://${GitHubUsername}:${GitHubToken}@github.com/${GitHubUsername}/${RepoName}.git"
git remote set-url origin $remoteUrl

Write-Host "🚀 Pushing to https://github.com/$GitHubUsername/$RepoName ..."
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Push thành công!"
    Write-Host "🔗 https://github.com/$GitHubUsername/$RepoName"

    # Create develop branch
    git checkout -b develop
    git push -u origin develop
    git checkout main
    Write-Host "✅ Branch 'develop' đã tạo"
} else {
    Write-Host "❌ Push thất bại. Kiểm tra:"
    Write-Host "   1. GitHub token có quyền 'repo'"
    Write-Host "   2. Repo '$RepoName' đã tồn tại trên GitHub"
    Write-Host "   3. Repo đang EMPTY (chưa có commit nào)"
}
