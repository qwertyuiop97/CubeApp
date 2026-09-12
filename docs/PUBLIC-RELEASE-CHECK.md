# Public-release preparation

## Verified cleanup

- Gitleaks 8.30.1 scanned the reachable Git history before cleanup: no detected secrets. This is automated detection, not a guarantee that every possible secret is absent.
- A label-only scan of historical file contents found no known owner names, personal-provider email addresses, home-directory paths, or tested private-network address patterns.
- Commit author/committer addresses across the 55 pre-cleanup commits used noreply addresses; tested owner-name and personal-email patterns were absent from commit metadata/messages. No privacy-driven history rewrite was indicated by these checks.
- GitHub's retrieved inventory contained no pull requests, issues, issue/review/commit comments, releases, or uploaded Actions artifacts. There were therefore no stale review threads to remove. Workflow logs were not comprehensively scanned; metadata inventory does not establish their contents are clean.
- Local agent permissions are no longer tracked. Private notes, downloaded source PDFs, and image drafts were preserved outside the public tree; recoverable pre-cleanup history and working-tree backups exist locally. Old files remain in Git history unless a separate history rewrite is approved.
- Ignore rules now cover local notes, agent settings, environment files, common credential containers, and Python caches.
- CI now fetches complete history and runs Gitleaks with redacted output before building/testing. Checkout does not persist credentials.
- GitHub's repository description was updated and read back. Visibility remains private during preparation.

## Workflow

[AGENTS.md](../AGENTS.md) defines development conventions; [NEXT.md](../NEXT.md) is the only current task queue. Historical prompts no longer compete with those instructions. Product limitations remain in [PROBLEMS.md](../PROBLEMS.md).

## Publication boundaries

No software license has been selected. Public visibility does not itself grant an open-source license. Preserve third-party attribution and do not assume external PDFs or reference content can be relicensed. No token rotation was indicated by the Git secret scan. No repository history, workflow runs, or reviews were deleted to conceal findings.
