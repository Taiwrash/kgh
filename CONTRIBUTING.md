# Contributing to KGH

First off, thanks for taking the time to contribute! 🎉

The following is a set of guidelines for contributing to KGH (Kubernetes GitOps Homelab). These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report for KGH. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.

- **Use a clear and descriptive title** for the issue to identify the problem.
- **Describe the exact steps which reproduce the problem** in as many details as possible.
- **Provide specific examples** to demonstrate the steps. Include links to files or GitHub projects, or copy/pasteable snippets, which you use in those examples.
- **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior.
- **Explain which behavior you expected to see instead and why.**
- **Include screenshots and animated GIFs** which show you following the described steps and clearly demonstrate the problem.

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion for KGH, including completely new features and minor improvements to existing functionality.

- **Use a clear and descriptive title** for the issue to identify the suggestion.
- **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
- **Provide specific examples** to demonstrate the steps.
- **Describe the current behavior** and **explain which behavior you expected to see instead** and why.

### Pull Requests

The process described here has several goals:

- Maintain KGH's quality
- Fix problems that are important to users
- Engage the community in working toward the best possible KGH
- Enable a sustainable system for KGH's maintainers to review contributions

Please follow these steps to have your contribution considered by the maintainers:

1.  Follow all instructions in [the template](.github/PULL_REQUEST_TEMPLATE.md) (if available).
2.  Follow the [styleguides](#styleguides)
3.  After you submit your pull request, verify that all status checks are passing <details><summary>What if the status checks are failing?</summary>If a status check is failing, and you believe that the failure is unrelated to your change, please leave a comment on the pull request explaining why you believe the failure is unrelated. A maintainer will re-run the status check for you. If we conclude that the failure was a false positive, then we will open an issue to track that problem with our status check suite.</details>

## Styleguides

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

### Go Styleguide

- We follow the [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md).
- Run `go fmt` before committing.
- Ensure `go vet` passes.

## Setting Up Your Development Environment

1.  Clone the repository:
    ```bash
    git clone https://github.com/Taiwrash/kgh.git
    cd kgh
    ```

2.  Install dependencies:
    ```bash
    go mod download
    ```

3.  Run tests:
    ```bash
    go test ./...
    ```

## Community

- Join our [Discord Server](https://discord.gg/your-discord-link) (if applicable)
- Follow us on [Twitter](https://twitter.com/your-handle) (if applicable)

Thanks! ❤️
