#requires -Version 5.1
<#
.SYNOPSIS
    把各个 App 项目 docs/ 目录里已生成的隐私政策 / 用户协议 HTML 复制到本站。

.DESCRIPTION
    本站只做“集成”，不生成条款文本。条款内容由各项目自己维护：
        <project>/flutter_project/docs/privacy*.html
        <project>/flutter_project/docs/terms*.html
    改动条款后重新跑一次本脚本即可同步。

    复制规则：
      * 显式映射（Files）：源文件改名成站点用的统一文件名。
      * 通配复制（Globs）：保持原文件名（例如 MD reader 的 privacy.en.html，
        因为多语言页里的 hreflang 链接指向这些名字）。

.EXAMPLE
    pwsh -File scripts\sync-from-projects.ps1

.EXAMPLE
    pwsh -File scripts\sync-from-projects.ps1 -ProjectsRoot 'E:\Projects'
#>
[CmdletBinding()]
param(
    # 站点根目录，默认是本脚本的上一级
    [string] $SiteRoot = (Split-Path -Parent $PSScriptRoot),

    # 各个 Flutter 项目所在根目录
    [string] $ProjectsRoot = 'D:\Projects'
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- 应用清单
# Slug      : 站点子目录 / App 名，同时用于 GitHub Pages 路径
# Source    : 该 App 生成条款文件的目录
# Files     : 显式改名映射，From 相对 Source，To 相对 SiteRoot\Slug
# Globs     : 保持原文件名的通配复制
$apps = @(
    [pscustomobject]@{
        Slug   = 'morse-craft'
        Name   = 'Morse Craft'
        Source = Join-Path $ProjectsRoot '1 Morse Craft\flutter_project\docs'
        Files  = @(
            @{ From = 'privacy_en.html'; To = 'privacy.html' }
            @{ From = 'privacy_zh.html'; To = 'privacy-zh.html' }
            @{ From = 'terms_en.html';   To = 'terms.html' }
            @{ From = 'terms_zh.html';   To = 'terms-zh.html' }
        )
        Globs  = @()
    }
    [pscustomobject]@{
        Slug   = 'id-photo-maker'
        Name   = 'ID Photo Maker'
        Source = Join-Path $ProjectsRoot '2 ID Photo Maker\flutter_project\docs'
        Files  = @(
            @{ From = 'privacy.html';    To = 'privacy.html' }
            @{ From = 'privacy_en.html'; To = 'privacy-en.html' }
            @{ From = 'privacy_zh.html'; To = 'privacy-zh.html' }
            @{ From = 'terms.html';      To = 'terms.html' }
            @{ From = 'terms_en.html';   To = 'terms-en.html' }
            @{ From = 'terms_zh.html';   To = 'terms-zh.html' }
        )
        Globs  = @()
    }
    [pscustomobject]@{
        Slug   = 'md-reader'
        Name   = 'MD Reader'
        Source = Join-Path $ProjectsRoot '4 MD reader\flutter_project\docs'
        Files  = @()
        Globs  = @('privacy*.html', 'terms*.html')
    }
    [pscustomobject]@{
        Slug   = 'any-convert'
        Name   = 'Any Convert'
        Source = Join-Path $ProjectsRoot '5 Format Convertor\flutter_project\docs'
        Files  = @(
            @{ From = 'privacy.html'; To = 'privacy.html' }
            @{ From = 'terms.html';   To = 'terms.html' }
        )
        Globs  = @()
        # 单独来源：单语言版本在 dist\legal 里
        Extra  = @(
            @{ From = (Join-Path $ProjectsRoot '5 Format Convertor\flutter_project\dist\legal\privacy-en.html'); To = 'privacy-en.html' }
            @{ From = (Join-Path $ProjectsRoot '5 Format Convertor\flutter_project\dist\legal\privacy-zh.html'); To = 'privacy-zh.html' }
        )
    }
)

# ---------------------------------------------------------------- 复制
$copied = 0
$totalBytes = 0
$report = @()

foreach ($app in $apps) {
    if (-not (Test-Path -LiteralPath $app.Source)) {
        throw "找不到 $($app.Name) 的条款目录：$($app.Source)"
    }

    $destDir = Join-Path $SiteRoot $app.Slug
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null

    $jobs = @()

    foreach ($f in $app.Files) {
        $src = Join-Path $app.Source $f.From
        if (-not (Test-Path -LiteralPath $src)) { throw "缺少源文件：$src" }
        $jobs += [pscustomobject]@{ Src = $src; Dest = (Join-Path $destDir $f.To) }
    }

    if ($app.Extra) {
        foreach ($f in $app.Extra) {
            if (-not (Test-Path -LiteralPath $f.From)) { throw "缺少源文件：$($f.From)" }
            $jobs += [pscustomobject]@{ Src = $f.From; Dest = (Join-Path $destDir $f.To) }
        }
    }

    foreach ($pattern in $app.Globs) {
        foreach ($file in Get-ChildItem -LiteralPath $app.Source -Filter $pattern -File) {
            $jobs += [pscustomobject]@{ Src = $file.FullName; Dest = (Join-Path $destDir $file.Name) }
        }
    }

    foreach ($job in $jobs) {
        Copy-Item -LiteralPath $job.Src -Destination $job.Dest -Force

        $bytes = (Get-Item -LiteralPath $job.Dest).Length
        $head = Get-Content -LiteralPath $job.Dest -TotalCount 3 -Encoding UTF8 | Out-String
        if ($head -notmatch '(?i)<!doctype|<html') {
            throw "复制结果不像 HTML，请检查：$($job.Src)"
        }

        $copied++
        $totalBytes += $bytes
        $report += [pscustomobject]@{
            App    = $app.Name
            Source = (Split-Path -Leaf $job.Src)
            Dest   = "$($app.Slug)/$(Split-Path -Leaf $job.Dest)"
            Size   = '{0:N1} KB' -f ($bytes / 1KB)
        }
    }
}

# ---------------------------------------------------------------- 汇总
$report | Format-Table -AutoSize

Write-Host ''
Write-Host ("已同步 {0} 个文件，共 {1:N0} KB。" -f $copied, ($totalBytes / 1KB)) -ForegroundColor Green
Write-Host '记得检查 git status，再提交推送。'
