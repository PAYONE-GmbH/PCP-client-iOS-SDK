# Contributing to the PAYONE Commerce Platform Client iOS SDK

Thank you for considering contributing to the PAYONE Commerce Platform Client iOS SDK! We appreciate your efforts to help improve this project. Below are guidelines for contributing.

## How to Contribute

### Pull Requests

We welcome pull requests! Please follow these steps to submit one:

1. **Fork** the repository and create your branch from `main`.
2. **Develop** your changes to work with both Swift and Objective-C.
3. **Unit test** your changes thoroughly.
4. **Add a demo** of your changes to both example projects to ensure and showcase that your changes work with UIKit/SwiftUI and Swift/Objective-C.
5. **Write** clear, concise, and self-explanatory commit messages. 
6. **Open** a pull request with a clear title and description of what your change does.
7. **Ensure** your pull request follows the [style guides](#style-guides).

### Reporting Bugs

If you encounter any bugs, please report them using one of the following methods:

1. **Issue Tracker**: Submit an issue through our [issues tracker](https://github.com/PAYONE-GmbH/PCP-client-ios-SDK/issues/new).
2. **Security Issues**: For security-related issues, please contact our IT support via email at tech.support@payone.com with a clear subject line indicating that it is a security issue. This ensures that the issue will be visible to and handled by the PAYONE tech support team.

## Style Guides

### Git Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/) for our commit messages. See the whole specification [here](https://www.conventionalcommits.org/en/v1.0.0/#specification).

### Swiftlint

- The project has a pre-commit-config which will run Swiftlint before each commit. Assure that your are using the same swiftlint version locally as stated in the [pre-commit-config.yaml](./.pre-commit-config.yaml).

### Testing

- Write unit tests.
- Ensure new features and bug fixes are covered by tests.
- Run the test suite to confirm all tests pass before submitting your pull request.

## Running the demo projects

- In order to test that the SDK still works after your changes assure that you run both demo projects with Objetive-C or Swift.

### Setup the demo projects

- Both demo projects include certain identifiers that need to be set on your end to run them successfully. These `String` values are prefixed with 'YOUR_' and can be replaced during testing.
- Make sure that you do not(!) commit those values since that would leak your secrets and they would be part of the Git history when pushed.

Thank you for your contributions!